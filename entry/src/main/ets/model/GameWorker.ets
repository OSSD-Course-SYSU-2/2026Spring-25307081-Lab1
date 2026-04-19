/**
 * 游戏Worker线程管理类
 * 负责在后台线程运行游戏逻辑，避免阻塞UI渲染
 */
export class GameWorker {
  private worker: Worker | null = null;
  private gameLoopId: number = 0;
  private gameLogic: SnakeGame | null = null;
  private messageHandler: ((data: any) => void) | null = null;
  
  constructor() {
    this.initWorker();
  }
  
  /**
   * 初始化Worker
   */
  private initWorker(): void {
    // 创建Worker脚本
    const workerScript = `
      let gameLogic = null;
      let gameLoopId = 0;
      let currentDirection = 'right';
      let gameSpeed = 400;
      
      self.onmessage = function(e) {
        const { type, payload } = e.data;
        
        switch (type) {
          case 'start':
            // 初始化游戏逻辑
            gameLogic = {
              gridWidth: payload.gridWidth || 30,
              gridHeight: payload.gridHeight || 20,
              snake: [],
              food: { x: 0, y: 0 },
              score: 0,
              gameOver: false,
              direction: 'right'
            };
            
            // 初始化蛇的位置
            const startX = Math.floor(gameLogic.gridWidth / 2);
            const startY = Math.floor(gameLogic.gridHeight / 2);
            gameLogic.snake = [
              { x: startX, y: startY },
              { x: startX - 1, y: startY },
              { x: startX - 2, y: startY }
            ];
            
            // 生成食物
            generateFood();
            gameSpeed = payload.speed || 400;
            
            // 开始游戏循环
            startGameLoop();
            break;
            
          case 'direction':
            // 更新方向（防止180度掉头）
            if (gameLogic && !gameLogic.gameOver) {
              const newDirection = payload;
              const currentDir = gameLogic.direction;
              
              if (!((currentDir === 'up' && newDirection === 'down') ||
                    (currentDir === 'down' && newDirection === 'up') ||
                    (currentDir === 'left' && newDirection === 'right') ||
                    (currentDir === 'right' && newDirection === 'left'))) {
                currentDirection = newDirection;
              }
            }
            break;
            
          case 'stop':
            // 停止游戏循环
            if (gameLoopId) {
              clearInterval(gameLoopId);
              gameLoopId = 0;
            }
            break;
            
          case 'pause':
            // 暂停游戏循环
            if (gameLoopId) {
              clearInterval(gameLoopId);
              gameLoopId = 0;
            }
            break;
            
          case 'resume':
            // 恢复游戏循环
            if (!gameLoopId && gameLogic && !gameLogic.gameOver) {
              startGameLoop();
            }
            break;
        }
      };
      
      // 生成食物
      function generateFood() {
        if (!gameLogic) return;
        
        let newFood;
        let isOnSnake;
        
        do {
          isOnSnake = false;
          newFood = {
            x: Math.floor(Math.random() * gameLogic.gridWidth),
            y: Math.floor(Math.random() * gameLogic.gridHeight)
          };
          
          // 检查食物是否生成在蛇身上
          for (const segment of gameLogic.snake) {
            if (segment.x === newFood.x && segment.y === newFood.y) {
              isOnSnake = true;
              break;
            }
          }
        } while (isOnSnake);
        
        gameLogic.food = newFood;
      }
      
      // 游戏循环
      function startGameLoop() {
        gameLoopId = setInterval(() => {
          if (!gameLogic || gameLogic.gameOver) {
            clearInterval(gameLoopId);
            gameLoopId = 0;
            return;
          }
          
          // 更新方向
          gameLogic.direction = currentDirection;
          
          // 计算新的蛇头位置
          const head = { ...gameLogic.snake[0] };
          
          switch (gameLogic.direction) {
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
          if (head.x < 0 || head.x >= gameLogic.gridWidth || 
              head.y < 0 || head.y >= gameLogic.gridHeight) {
            gameLogic.gameOver = true;
            self.postMessage({
              type: 'gameUpdate',
              payload: {
                snake: [...gameLogic.snake],
                food: { ...gameLogic.food },
                score: gameLogic.score,
                gameOver: true
              }
            });
            return;
          }
          
          // 自身碰撞检测
          for (const segment of gameLogic.snake) {
            if (segment.x === head.x && segment.y === head.y) {
              gameLogic.gameOver = true;
              self.postMessage({
                type: 'gameUpdate',
                payload: {
                  snake: [...gameLogic.snake],
                  food: { ...gameLogic.food },
                  score: gameLogic.score,
                  gameOver: true
                }
              });
              return;
            }
          }
          
          // 移动蛇
          gameLogic.snake.unshift(head);
          
          // 检查是否吃到食物
          if (head.x === gameLogic.food.x && head.y === gameLogic.food.y) {
            // 吃到食物，增加分数，生成新食物
            gameLogic.score += 10;
            generateFood();
            
            // 随着分数增加，游戏速度加快
            if (gameLogic.score % 50 === 0 && gameSpeed > 50) {
              gameSpeed -= 10;
              clearInterval(gameLoopId);
              startGameLoop(); // 重新启动循环以应用新速度
            }
          } else {
            // 没吃到食物，移除蛇尾
            gameLogic.snake.pop();
          }
          
          // 发送游戏状态更新
          self.postMessage({
            type: 'gameUpdate',
            payload: {
              snake: [...gameLogic.snake],
              food: { ...gameLogic.food },
              score: gameLogic.score,
              gameOver: false
            }
          });
        }, gameSpeed);
      }
    `;
    
    // 创建Blob URL并初始化Worker
    const blob = new Blob([workerScript], { type: 'application/javascript' });
    const workerURL = URL.createObjectURL(blob);
    
    try {
      this.worker = new Worker(workerURL);
      
      // 设置消息处理器
      this.worker.onmessage = (event: MessageEvent) => {
        if (this.messageHandler) {
          this.messageHandler(event.data);
        }
      };
      
      // 设置错误处理器
      this.worker.onerror = (error: ErrorEvent) => {
        console.error('GameWorker error:', error);
      };
    } catch (error) {
      console.error('Failed to create GameWorker:', error);
    }
  }
  
  /**
   * 设置消息处理器
   */
  public set onmessage(handler: (data: any) => void) {
    this.messageHandler = handler;
  }
  
  /**
   * 向Worker发送消息
   */
  public postMessage(message: any): void {
    if (this.worker) {
      this.worker.postMessage(message);
    }
  }
  
  /**
   * 启动游戏循环
   */
  public startGame(gridWidth: number, gridHeight: number, speed: number = 200): void {
    this.postMessage({
      type: 'start',
      payload: {
        gridWidth,
        gridHeight,
        speed
      }
    });
  }
  
  /**
   * 更新方向
   */
  public updateDirection(direction: 'up' | 'down' | 'left' | 'right'): void {
    this.postMessage({
      type: 'direction',
      payload: direction
    });
  }
  
  /**
   * 暂停游戏
   */
  public pauseGame(): void {
    this.postMessage({ type: 'pause' });
  }
  
  /**
   * 恢复游戏
   */
  public resumeGame(): void {
    this.postMessage({ type: 'resume' });
  }
  
  /**
   * 停止游戏并终止Worker
   */
  public terminate(): void {
    this.postMessage({ type: 'stop' });
    
    if (this.worker) {
      this.worker.terminate();
      this.worker = null;
    }
  }
}