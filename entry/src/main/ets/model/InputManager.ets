/**
 * 输入管理器
 * 负责处理键盘和触摸输入，实现防抖动逻辑
 */
export class InputManager {
  // 防抖动时间间隔（毫秒）
  private static readonly DEBOUNCE_INTERVAL = 100;
  
  // 最后按键时间戳
  private lastKeyTime: number = 0;
  
  // 最后触摸时间戳
  private lastTouchTime: number = 0;
  
  // 触摸起始位置
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  
  // 当前方向
  private currentDirection: 'up' | 'down' | 'left' | 'right' = 'right';
  
  // 方向变化回调
  private directionChangeCallback: ((direction: 'up' | 'down' | 'left' | 'right') => void) | null = null;
  
  /**
   * 设置方向变化回调
   */
  public setDirectionChangeCallback(callback: (direction: 'up' | 'down' | 'left' | 'right') => void): void {
    this.directionChangeCallback = callback;
  }
  
  /**
   * 处理键盘事件
   */
  public handleKeyEvent(event: KeyEvent): void {
    // 防抖动：100ms内禁止重复响应
    const now = Date.now();
    if (now - this.lastKeyTime < InputManager.DEBOUNCE_INTERVAL) {
      return;
    }
    
    let newDirection: 'up' | 'down' | 'left' | 'right' | null = null;
    
    // 处理WASD和方向键
    switch (event.keyCode) {
      case 87: // W
      case 38: // 上箭头
        newDirection = 'up';
        break;
      case 83: // S
      case 40: // 下箭头
        newDirection = 'down';
        break;
      case 65: // A
      case 37: // 左箭头
        newDirection = 'left';
        break;
      case 68: // D
      case 39: // 右箭头
        newDirection = 'right';
        break;
    }
    
    if (newDirection) {
      // 防止180度掉头
      if ((this.currentDirection === 'up' && newDirection === 'down') ||
          (this.currentDirection === 'down' && newDirection === 'up') ||
          (this.currentDirection === 'left' && newDirection === 'right') ||
          (this.currentDirection === 'right' && newDirection === 'left')) {
        return;
      }
      
      this.updateDirection(newDirection);
      this.lastKeyTime = now;
    }
  }
  
  /**
   * 处理触摸事件
   */
  public handleTouchEvent(event: TouchEvent): void {
    // 防抖动：100ms内禁止重复响应
    const now = Date.now();
    if (now - this.lastTouchTime < InputManager.DEBOUNCE_INTERVAL) {
      return;
    }
    
    if (event.type === TouchType.Down) {
      // 记录触摸开始位置
      this.touchStartX = event.touches[0].x;
      this.touchStartY = event.touches[0].y;
    } else if (event.type === TouchType.Up) {
      // 计算滑动方向
      const endX = event.touches[0].x;
      const endY = event.touches[0].y;
      const dx = endX - this.touchStartX;
      const dy = endY - this.touchStartY;
      
      // 判断滑动方向（绝对值大于20像素才视为有效滑动）
      if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 20) {
        // 水平滑动
        let newDirection: 'left' | 'right' | null = null;
        if (dx > 0) {
          newDirection = 'right';
        } else {
          newDirection = 'left';
        }
        
        // 防止180度掉头
        if (newDirection && 
            !((this.currentDirection === 'left' && newDirection === 'right') ||
              (this.currentDirection === 'right' && newDirection === 'left'))) {
          this.updateDirection(newDirection);
          this.lastTouchTime = now;
        }
      } else if (Math.abs(dy) > 20) {
        // 垂直滑动
        let newDirection: 'up' | 'down' | null = null;
        if (dy > 0) {
          newDirection = 'down';
        } else {
          newDirection = 'up';
        }
        
        // 防止180度掉头
        if (newDirection && 
            !((this.currentDirection === 'up' && newDirection === 'down') ||
              (this.currentDirection === 'down' && newDirection === 'up'))) {
          this.updateDirection(newDirection);
          this.lastTouchTime = now;
        }
      }
    }
  }
  
  /**
   * 更新方向并触发回调
   */
  private updateDirection(direction: 'up' | 'down' | 'left' | 'right'): void {
    this.currentDirection = direction;
    
    if (this.directionChangeCallback) {
      this.directionChangeCallback(direction);
    }
  }
  
  /**
   * 获取当前方向
   */
  public getCurrentDirection(): 'up' | 'down' | 'left' | 'right' {
    return this.currentDirection;
  }
  
  /**
   * 重置输入状态
   */
  public reset(): void {
    this.currentDirection = 'right';
    this.lastKeyTime = 0;
    this.lastTouchTime = 0;
  }
}