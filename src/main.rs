#![feature(generic_const_exprs)]

use std::{io::Write, thread, time::Duration};
use serialport::{SerialPort, TTYPort};
use sysinfo::{CpuRefreshKind, MemoryRefreshKind, RefreshKind, System};

fn update_matrix(dev: &mut TTYPort, percent: u8) {
	let dev_path = dev.name().unwrap_or(String::new());
	match dev.write(&[0x32, 0xAC, 0x01, 0x00, percent]) {
		Ok(val) => println!("Wrote {} bytes to {}", val, &dev_path),
		Err(e) => println!("Ran into error while writing to {}!: {}", &dev_path, e)
	}
}
fn main() {
	let mut sys = System::new_with_specifics(RefreshKind::nothing()
		.with_cpu(CpuRefreshKind::nothing().with_cpu_usage())
		.with_memory(MemoryRefreshKind::nothing().with_ram())
	);
	let mut left_matrix = serialport::new("/dev/ttyACM1", 115200).open_native().expect("Can't open the given serial device!");
	let mut right_matrix = serialport::new("/dev/ttyACM0", 115200).open_native().expect("Can't open the given serial device!");
	loop {
		sys.refresh_cpu_specifics(CpuRefreshKind::nothing().with_cpu_usage());
		sys.refresh_memory_specifics(MemoryRefreshKind::nothing().with_ram());
		update_matrix(&mut left_matrix, sys.global_cpu_usage() as u8);
		update_matrix(&mut right_matrix, (sys.used_memory() as f64 / sys.total_memory() as f64 * 100.0) as u8);
		thread::sleep(Duration::from_secs(1));
	}
}