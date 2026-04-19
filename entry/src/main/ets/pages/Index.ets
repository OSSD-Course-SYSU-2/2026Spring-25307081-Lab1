// Index.ets
import promptAction from '@ohos.promptAction';
import { KeyCode } from '@kit.InputKit';

// 定义方向枚举
enum Direction {
  UP,
  DOWN,
  LEFT,
  RIGHT
}

// 定义蛇的节点
interface SnakeNode {
  x: number;
  y: number;
}

// 游戏配置
const GAME_WIDTH = 20;  // 格子数（宽）
const GAME_HEIGHT = 15; // 格子数（高）
const CELL_SIZE = 20;   // 每个格子的像素大小

@Entry
@Component
struct Index {
  // 蛇的身体数组，第一个元素是蛇头
  @State snake: SnakeNode[] = [{x: 5, y: 5}, {x: 4, y: 5}, {x: 3, y: 5}];
  // 苹果位置
  @State apple: SnakeNode = {x: 10, y: 7};
  // 当前方向
  @State moveDirection: Direction = Direction.RIGHT;
  // 游戏是否在运行
  @State isRunning: boolean = false;
  // 游戏是否结束
  @State isGameOver: boolean = false;
  // 分数
  @State score: number = 0;
  // 定时器
  private timer: number = -1;

  aboutToAppear(): void {
    // 初始化苹果位置
    this.apple = this.generateApple();
  }

  aboutToDisappear(): void {
    // 组件销毁时清除定时器
    this.stopGame();
  }

  // 生成随机苹果（不能出现在蛇身上）
  private generateApple(): SnakeNode {
    let apple: SnakeNode;
    let attempts = 0;
    do {
      apple = {
        x: Math.floor(Math.random() * GAME_WIDTH),
        y: Math.floor(Math.random() * GAME_HEIGHT)
      };
      attempts++;
    } while (this.snake.some(node => node.x === apple.x && node.y === apple.y) && attempts < 100);
    return apple;
  }

  // 开始游戏
  private startGame() {
    if (this.isRunning) return;
    // 如果游戏已结束，先重置
    if (this.isGameOver) {
      this.snake = [{x: 5, y: 5}, {x: 4, y: 5}, {x: 3, y: 5}];
      this.apple = this.generateApple();
      this.moveDirection = Direction.RIGHT;
      this.score = 0;
      this.isGameOver = false;
    }
    this.isRunning = true;
    this.timer = setInterval(() => {
      this.moveSnake();
    }, 200);
  }

  // 停止游戏
  private stopGame() {
    this.isRunning = false;
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  // 重置游戏
  private resetGame() {
    this.stopGame();
    this.snake = [{x: 5, y: 5}, {x: 4, y: 5}, {x: 3, y: 5}];
    this.apple = this.generateApple();
    this.moveDirection = Direction.RIGHT;
    this.score = 0;
    this.isGameOver = false;
  }

  // 蛇移动逻辑
  private moveSnake() {
    // 计算新蛇头位置
    let head: SnakeNode = { x: this.snake[0].x, y: this.snake[0].y };
    switch (this.moveDirection) {
      case Direction.UP:
        head.y -= 1;
        break;
      case Direction.DOWN:
        head.y += 1;
        break;
      case Direction.LEFT:
        head.x -= 1;
        break;
      case Direction.RIGHT:
        head.x += 1;
        break;
    }

    // 边界碰撞检测
    if (head.x < 0 || head.x >= GAME_WIDTH || head.y < 0 || head.y >= GAME_HEIGHT) {
      this.gameOver();
      return;
    }

    // 自身碰撞检测
    if (this.snake.some(node => node.x === head.x && node.y === head.y)) {
      this.gameOver();
      return;
    }

    // 创建新的蛇数组（触发UI更新）
    let newSnake = [...this.snake];
    newSnake.unshift(head);

    // 判断是否吃到苹果
    if (head.x === this.apple.x && head.y === this.apple.y) {
      this.score += 10;
      this.snake = newSnake;
      this.apple = this.generateApple();
    } else {
      // 没吃到苹果就去掉尾巴（保持长度）
      newSnake.pop();
      this.snake = newSnake;
    }
  }

  // 游戏结束
  private gameOver() {
    this.stopGame();
    this.isGameOver = true;
    promptAction.showToast({
      message: `游戏结束！你的分数：${this.score}`,
      duration: 2000
    });
  }

  // 键盘控制方向
  private handleKeyEvent(event: KeyEvent): void {
    if (event.type === KeyType.Down) {
      switch (event.keyCode) {
        // 方向键控制
        case KeyCode.KEYCODE_DPAD_UP:
        case KeyCode.KEYCODE_W:  // W键向上
          if (this.moveDirection !== Direction.DOWN) this.moveDirection = Direction.UP;
          break;
        case KeyCode.KEYCODE_DPAD_DOWN:
        case KeyCode.KEYCODE_S:  // S键向下
          if (this.moveDirection !== Direction.UP) this.moveDirection = Direction.DOWN;
          break;
        case KeyCode.KEYCODE_DPAD_LEFT:
        case KeyCode.KEYCODE_A:  // A键向左
          if (this.moveDirection !== Direction.RIGHT) this.moveDirection = Direction.LEFT;
          break;
        case KeyCode.KEYCODE_DPAD_RIGHT:
        case KeyCode.KEYCODE_D:  // D键向右
          if (this.moveDirection !== Direction.LEFT) this.moveDirection = Direction.RIGHT;
          break;
      }
    }
  }

  build() {
    Column() {
      // 标题和分数
      Text('🐍 贪吃蛇游戏')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
      Text(`分数：${this.score}`)
        .fontSize(20)
        .margin({ bottom: 10 })

      // 游戏区域
      Stack() {
        // 渲染蛇
        ForEach(this.snake, (node: SnakeNode, index: number) => {
          Rect()
            .width(CELL_SIZE)
            .height(CELL_SIZE)
            .fill(index === 0 ? '#00FF00' : '#00CC00')
            .position({
              x: node.x * CELL_SIZE,
              y: node.y * CELL_SIZE
            })
        }, (node: SnakeNode, index: number) => `${node.x}-${node.y}-${index}`)

        // 苹果
        Rect()
          .width(CELL_SIZE)
          .height(CELL_SIZE)
          .fill('#FF0000')
          .position({
            x: this.apple.x * CELL_SIZE,
            y: this.apple.y * CELL_SIZE
          })
      }
      .width(GAME_WIDTH * CELL_SIZE)
      .height(GAME_HEIGHT * CELL_SIZE)
      .backgroundColor('#F0F0F0')
      .border({ width: 2, color: '#333333' })
      .margin({ bottom: 20 })

      // 控制按钮
      Row() {
        Button('开始')
          .onClick(() => this.startGame())
          .margin(5)
        Button('暂停')
          .onClick(() => this.stopGame())
          .margin(5)
        Button('重置')
          .onClick(() => this.resetGame())
          .margin(5)
      }

      Text('使用方向键 ↑↓←→ 或 WASD 控制蛇移动')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onKeyEvent((event: KeyEvent) => this.handleKeyEvent(event))
  }
}
