use criterion::{black_box, criterion_group, criterion_main, Criterion};
use opal_vte::Grid;

fn grid_write(c: &mut Criterion) {
    let mut grid = Grid::new(24, 80, 1000);

    c.bench_function("grid write cell", |b| {
        b.iter(|| {
            for row in 0..24 {
                for col in 0..80 {
                    black_box(grid.get_cell(row, col));
                }
            }
        })
    });
}

fn grid_scroll(c: &mut Criterion) {
    let mut grid = Grid::new(24, 80, 1000);

    c.bench_function("grid scroll up", |b| {
        b.iter(|| {
            grid.scroll_up(1);
            black_box(&grid);
        })
    });
}

criterion_group!(benches, grid_write, grid_scroll);
criterion_main!(benches);
