// 経路探索（Dijkstra法）用の優先度付きキュー（あんしんみち由来）。
export interface MinHeapEntry<T> {
  item: T;
  priority: number;
}

export class MinHeap<T> {
  private items: Array<MinHeapEntry<T>> = [];

  isEmpty(): boolean {
    return this.items.length === 0;
  }

  push(item: T, priority: number): void {
    this.items.push({ item, priority });
    this.bubbleUp(this.items.length - 1);
  }

  pop(): MinHeapEntry<T> | undefined {
    const top = this.items[0];
    const last = this.items.pop();
    if (this.items.length > 0 && last !== undefined) {
      this.items[0] = last;
      this.bubbleDown(0);
    }
    return top;
  }

  private bubbleUp(index: number): void {
    let current = index;
    while (current > 0) {
      const parent = (current - 1) >> 1;
      if (this.items[parent].priority <= this.items[current].priority) break;
      [this.items[parent], this.items[current]] = [this.items[current], this.items[parent]];
      current = parent;
    }
  }

  private bubbleDown(index: number): void {
    let current = index;
    const length = this.items.length;
    for (;;) {
      const left = current * 2 + 1;
      const right = current * 2 + 2;
      let smallest = current;
      if (left < length && this.items[left].priority < this.items[smallest].priority) {
        smallest = left;
      }
      if (right < length && this.items[right].priority < this.items[smallest].priority) {
        smallest = right;
      }
      if (smallest === current) break;
      [this.items[smallest], this.items[current]] = [this.items[current], this.items[smallest]];
      current = smallest;
    }
  }
}
