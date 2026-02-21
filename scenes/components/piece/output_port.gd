class_name OutputPort
extends Sprite2D

## 出力ポートの矢印表示。位置・回転を自律計算するコンポーネント。

const PORT_OFFSET = 35.0


func setup(ports: Array):
	if ports.is_empty():
		visible = false
		return

	visible = true

	var layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2.ZERO)

	# NOTE: ports が複数の場合は未対応なので注意
	var port = ports[0]

	var center_pos = Layout.hex_to_pixel(layout, port.hex)
	var neighbor_hex = Hex.neighbor(port.hex, port.direction)
	var neighbor_pos = Layout.hex_to_pixel(layout, neighbor_hex)
	var angle = (neighbor_pos - center_pos).angle()

	position = center_pos + Vector2(PORT_OFFSET, 0).rotated(angle)
	rotation = angle
