/**
 * 简化的贪吃蛇游戏逻辑类
 * 负责处理蛇的移动、食物生成、碰撞检测等游戏逻辑
 */
export class SimpleSnakeGame {
  // 游戏配置
  private gridWidth: number;
  private gridHeight: number;
  
  // 游戏状态
  private snake: Array<[number, number]> = [];
  private food: [number, number] = [0, 0];
  private direction: string = 'right';
  private nextDirection: string = 'right';
  private score: number = 0;
  private gameOver: boolean = false;
  private gameSpeed: number = 400;
  
  constructor(gridWidth: number = 30, gridHeight: number = 20) {
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
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
      [startX, startY],
      [startX - 1, startY],
      [startX - 2, startY]
    ];
    
    // 初始化方向
    this.direction = 'right';
    this.nextDirection = 'right';
    
    // 生成食物
    this.generateFood();
    
    // 重置游戏状态
    this.score = 0;
    this.gameOver = false;
    this.gameSpeed = 400;
  }
  
  /**
   * 生成食物
   * 确保食物不会生成在蛇身上
   */
  private generateFood(): void {
    let newFood: [number, number];
    let isOnSnake: boolean;
    
    do {
      isOnSnake = false;
      newFood = [
        Math.floor(Math.random() * this.gridWidth),
        Math.floor(Math.random() * this.gridHeight)
      ];
      
      // 检查食物是否生成在蛇身上
      for (const segment of this.snake) {
        if (segment[0] === newFood[0] && segment[1] === newFood[1]) {
          isOnSnake = true;
          break;
        }
      }
    } while (isOnSnake);
    
    this.food = newFood;
  }
  
  /**
   * 设置蛇的移动方向
   * @param direction 新的移动方向
   */
  public setDirection(direction: string): void {
    // 防止180度掉头
    if ((this.direction === 'up' && direction === 'down') ||
        (this.direction === 'down' && direction === 'up') ||
        (this.direction === 'left' && direction === 'right') ||
        (this.direction === 'right' && direction === 'left')) {
      return;
    }
    
    this.nextDirection = direction;
  }
  
  /**
   * 更新游戏状态
   * @returns 返回游戏是否结束
   */
  public update(): boolean {
    if (this.gameOver) {
      return true;
    }
    
    // 更新方向
    this.direction = this.nextDirection;
    
    // 计算新的蛇头位置
    const head: [number, number] = [this.snake[0][0], this.snake[0][1]];
    
    switch (this.direction) {
      case 'up':
        head[1] -= 1;
        break;
      case 'down':
        head[1] += 1;
        break;
      case 'left':
        head[0] -= 1;
        break;
      case 'right':
        head[0] += 1;
        break;
    }
    
    // 边界检测
    if (head[0] < 0 || head[0] >= this.gridWidth || 
        head[1] < 0 || head[1] >= this.gridHeight) {
      this.gameOver = true;
      return true;
    }
    
    // 自身碰撞检测
    for (const segment of this.snake) {
      if (segment[0] === head[0] && segment[1] === head[1]) {
        this.gameOver = true;
        return true;
      }
    }
    
    // 移动蛇
    this.snake.unshift(head);
    
    // 检查是否吃到食物
    if (head[0] === this.food[0] && head[1] === this.food[1]) {
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
    
    return false;
  }
  
  /**
   * 获取蛇的身体坐标
   */
  public getSnake(): Array<[number, number]> {
    return this.snake.map(segment => [segment[0], segment[1]]);
  }
  
  /**
   * 获取食物坐标
   */
  public getFood(): [number, number] {
    return [this.food[0], this.food[1]];
  }
  
  /**
   * 获取当前分数
   */
  public getScore(): number {
    return this.score;
  }
  
  /**
   * 获取游戏是否结束
   */
  public isGameOver(): boolean {
    return this.gameOver;
  }
  
  /**
   * 获取游戏速度
   */
  public getGameSpeed(): number {
    return this.gameSpeed;
  }
  
  /**
   * 获取当前方向
   */
  public getDirection(): string {
    return this.direction;
  }
  
  /**
   * 重置游戏
   */
  public reset(): void {
    this.initGame();
  }
}