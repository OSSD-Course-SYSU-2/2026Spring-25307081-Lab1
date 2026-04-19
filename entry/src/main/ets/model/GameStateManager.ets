/**
 * 游戏状态管理器
 * 负责管理游戏状态、分数计算和游戏逻辑
 */
export class GameStateManager {
  // 游戏状态
  private snake: Array<{ x: number, y: number }> = [];
  private food: { x: number, y: number } = { x: 0, y: 0 };
  private score: number = 0;
  private gameStatus: 'playing' | 'paused' | 'gameOver' = 'paused';
  private direction: 'up' | 'down' | 'left' | 'right' = 'right';
  
  // 游戏配置
  private gridWidth: number;
  private gridHeight: number;
  private gameSpeed: number;
  
  // 状态变化回调
  private stateChangeCallbacks: Array<(state: GameState) => void> = [];
  
  // 游戏状态接口
  interface GameState {
    snake: Array<{ x: number, y: number }>;
    food: { x: number, y: number };
    score: number;
    gameStatus: 'playing' | 'paused' | 'gameOver';
    direction: 'up' | 'down' | 'left' | 'right';
    gridWidth: number;
    gridHeight: number;
  }
  
  constructor(gridWidth: number = 30, gridHeight: number = 20, initialSpeed: number = 200) {
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.gameSpeed = initialSpeed;
    this.initGame();
  }
  
  /**
   * 初始化游戏
   */
  public initGame(): void {
    // 初始化蛇的位置（在画布中间）
    const startX = Math.floor(this.gridWidth / 2);
    const startY = Math.floor(this.gridHeight / 2);
    
    this.snake = [
      { x: startX, y: startY },
      { x: startX - 1, y: startY },
      { x: startX - 2, y: startY }
    ];
    
    // 初始化方向
    this.direction = 'right';
    
    // 生成食物
    this.generateFood();
    
    // 重置游戏状态
    this.score = 0;
    this.gameStatus = 'paused';
    
    // 通知状态变化
    this.notifyStateChange();
  }
  
  /**
   * 生成食物
   * 确保食物不会生成在蛇身上
   */
  private generateFood(): void {
    let newFood: { x: number, y: number };
    let isOnSnake: boolean;
    
    do {
      isOnSnake = false;
      newFood = {
        x: Math.floor(Math.random() * this.gridWidth),
        y: Math.floor(Math.random() * this.gridHeight)
      };
      
      // 检查食物是否生成在蛇身上
      for (const segment of this.snake) {
        if (segment.x === newFood.x && segment.y === newFood.y) {
          isOnSnake = true;
          break;
        }
      }
    } while (isOnSnake);
    
    this.food = newFood;
  }
  
  /**
   * 更新方向
   */
  public updateDirection(newDirection: 'up' | 'down' | 'left' | 'right'): void {
    // 防止180度掉头
    if ((this.direction === 'up' && newDirection === 'down') ||
        (this.direction === 'down' && newDirection === 'up') ||
        (this.direction === 'left' && newDirection === 'right') ||
        (this.direction === 'right' && newDirection === 'left')) {
      return;
    }
    
    this.direction = newDirection;
    this.notifyStateChange();
  }
  
  /**
   * 更新游戏状态（移动蛇）
   */
  public updateGame(): boolean {
    if (this.gameStatus !== 'playing') {
      return false;
    }
    
    // 计算新的蛇头位置
    const head = { ...this.snake[0] };
    
    switch (this.direction) {
      case 'up':
        head.y -= 1;
        break;
      case 'down':
        head.y += 1;
        break;
      case 'left':
        head.x -= 1;
        break;
      case 'right':
        head.x += 1;
        break;
    }
    
    // 边界检测
    if (head.x < 0 || head.x >= this.gridWidth || 
        head.y < 0 || head.y >= this.gridHeight) {
      this.gameStatus = 'gameOver';
      this.notifyStateChange();
      return true;
    }
    
    // 自身碰撞检测
    for (const segment of this.snake) {
      if (segment.x === head.x && segment.y === head.y) {
        this.gameStatus = 'gameOver';
        this.notifyStateChange();
        return true;
      }
    }
    
    // 移动蛇
    this.snake.unshift(head);
    
    // 检查是否吃到食物
    if (head.x === this.food.x && head.y === this.food.y) {
      // 吃到食物，增加分数，生成新食物
      this.score += 10;
      this.generateFood();
      
      // 随着分数增加，游戏速度加快
      if (this.score % 50 === 0 && this.gameSpeed > 50) {
        this.gameSpeed -= 10;
      }
    } else {
      // 没吃到食物，移除蛇尾
      this.snake.pop();
    }
    
    this.notifyStateChange();
    return false;
  }
  
  /**
   * 开始游戏
   */
  public startGame(): void {
    if (this.gameStatus === 'gameOver') {
      this.initGame();
    }
    this.gameStatus = 'playing';
    this.notifyStateChange();
  }
  
  /**
   * 暂停游戏
   */
  public pauseGame(): void {
    this.gameStatus = 'paused';
    this.notifyStateChange();
  }
  
  /**
   * 重新开始游戏
   */
  public restartGame(): void {
    this.initGame();
    this.startGame();
  }
  
  /**
   * 添加状态变化监听器
   */
  public addStateChangeListener(callback: (state: GameState) => void): void {
    this.stateChangeCallbacks.push(callback);
  }
  
  /**
   * 移除状态变化监听器
   */
  public removeStateChangeListener(callback: (state: GameState) => void): void {
    const index = this.stateChangeCallbacks.indexOf(callback);
    if (index > -1) {
      this.stateChangeCallbacks.splice(index, 1);
    }
  }
  
  /**
   * 通知状态变化
   */
  private notifyStateChange(): void {
    const state: GameState = {
      snake: [...this.snake],
      food: { ...this.food },
      score: this.score,
      gameStatus: this.gameStatus,
      direction: this.direction,
      gridWidth: this.gridWidth,
      gridHeight: this.gridHeight
    };
    
    this.stateChangeCallbacks.forEach(callback => {
      callback(state);
    });
  }
  
  /**
   * 获取当前游戏状态
   */
  public getGameState(): GameState {
    return {
      snake: [...this.snake],
      food: { ...this.food },
      score: this.score,
      gameStatus: this.gameStatus,
      direction: this.direction,
      gridWidth: this.gridWidth,
      gridHeight: this.gridHeight
    };
  }
  
  /**
   * 获取游戏速度
   */
  public getGameSpeed(): number {
    return this.gameSpeed;
  }
  
  /**
   * 获取游戏状态
   */
  public getGameStatus(): 'playing' | 'paused' | 'gameOver' {
    return this.gameStatus;
  }
  
  /**
   * 获取当前分数
   */
  public getScore(): number {
    return this.score;
  }
}