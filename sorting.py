# sorting.py - 冒泡排序示例
def bubble_sort(arr):
    n = len(arr)
    # 遍历所有数组元素
    for i in range(n):
        # 最后 i 个元素已经有序, 无需再比较
        for j in range(0, n-i-1):
            # 两两比较
            if arr[j] > arr[j+1]:
                # 如果当前元素大于下一个, 交换位置
                arr[j], arr[j+1] = arr[j+1], arr[j]
    return arr

# 测试代码
if __name__ == "__main__":
    test_array = [64, 34, 25, 12, 22, 11, 90]
    sorted_array = bubble_sort(test_array)
    print("排序后的数组:", sorted_array)