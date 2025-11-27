use std::{env, io::{Read, Write}, thread, time::Duration};
use serialport::{SerialPort, TTYPort};
use sysinfo::{CpuRefreshKind, MemoryRefreshKind, RefreshKind, System};

fn panic_if_broken_pipe(e: &std::io::Error) {
	if e.kind() == std::io::ErrorKind::BrokenPipe {
		panic!("One of the LED matrices disconnected! Aborting...")
	}
}

fn get_sleep_status(dev: &mut TTYPort) -> Option<bool> {
	let dev_path = dev.name().unwrap_or(String::new());
	match dev.write(&[0x32, 0xAC, 0x03]) {
		Ok(_) => (),
		Err(e) => {
			panic_if_broken_pipe(&e);
			println!("Can't get sleep status of {}!: {}", &dev_path, e)
		}
	};
	let mut response = [0u8; 1];
	match dev.read(&mut response) {
		Ok(val) if val > 0 => Some(response[0] != 0),
		Ok(_) => None,
		Err(e) => {
			panic_if_broken_pipe(&e);
			println!("Ran into problem while reading from {}!: {}", &dev_path, e);
			None
		}
	}
}

fn get_sleep_statuses(dev1: &mut TTYPort, dev2: &mut TTYPort) -> (Option<bool>, Option<bool>) {
	(
		match get_sleep_status(dev1) {
			Some(val) => Some(val),
			None => None
		},
		match get_sleep_status(dev2) {
			Some(val) => Some(val),
			None => None
		}
	)
}

fn update_matrix(dev: &mut TTYPort, percent: u8) {
	match dev.write(&[0x32, 0xAC, 0x01, 0x00, percent]) {
		Ok(_) => (),
		Err(e) => {
			panic_if_broken_pipe(&e);
			println!("Ran into problem while writing to {}!: {}", dev.name().unwrap_or(String::new()), e)
		}
	}
}

fn main() {
	let args: Vec<String> = env::args().collect();
	let interval_ms = if args.len() > 1 {
        args[1].parse::<u64>().unwrap_or(1000)
    } else {
        1000
    };
	let mut sys = System::new_with_specifics(RefreshKind::nothing()
		.with_cpu(CpuRefreshKind::nothing().with_cpu_usage())
		.with_memory(MemoryRefreshKind::nothing().with_ram())
	);
	let available_ttyports = serialport::available_ports().expect("Can't get list of serial ports for some reason")
		.into_iter().filter(|port| port.port_name.starts_with("/dev/ttyACM")).collect::<Vec<_>>();
	if available_ttyports.is_empty() {
		panic!("No ttyACM ports found! Are the LED matrix modules attached?");
	}
	let mut left_matrix = serialport::new(&available_ttyports.get(1).expect("Failed to start left LED matrix module!").port_name, 115200).open_native().unwrap();
	let mut right_matrix = serialport::new(&available_ttyports.get(0).expect("Failed to start right LED matrix module!").port_name, 115200).open_native().unwrap();
	loop {
		if let (Some(left_sleeping), Some(right_sleeping)) = get_sleep_statuses(&mut left_matrix, &mut right_matrix) {
			if !left_sleeping && !right_sleeping {
				sys.refresh_cpu_specifics(CpuRefreshKind::nothing().with_cpu_usage());
				sys.refresh_memory_specifics(MemoryRefreshKind::nothing().with_ram());
				update_matrix(&mut left_matrix, sys.global_cpu_usage() as u8);
				update_matrix(&mut right_matrix, (sys.used_memory() as f64 / sys.total_memory() as f64 * 100.0) as u8);
			}
		}
		thread::sleep(Duration::from_millis(interval_ms));
	}
}
