export function randomGaussian(): number {
  let u = 1 - Math.random();
  let v = Math.random();
  return Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
}

export function random(a: number, b: number): number {
  return a + Math.random() * (b - a);
}

export function randomSign(): number {
  return Math.random() < 0.5 ? 1 : -1;
}