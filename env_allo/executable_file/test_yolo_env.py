import cv2
from ultralytics import YOLO

model = YOLO('yolo11n.pt')  # 可以换成你的 best.pt

img = cv2.imread('test.jpg')
if img is None:
    print("无法读取 test.jpg，请确保图片存在")
    exit()

results = model(img)

# 关键：遍历 results
for result in results:               # 注意冒号和缩进
    boxes = result.boxes.xyxy.cpu().numpy()
    for box in boxes:
        x1, y1, x2, y2 = map(int, box)
        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(img, 'Target', (x1, y1-10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

cv2.imshow('YOLO Detection', img)
cv2.waitKey(0)
cv2.destroyAllWindows()