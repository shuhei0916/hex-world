extends GutTest


func test_生成直後は最大HPで生きている():
	var unit := Unit.new(Unit.Team.PLAYER, 10, 3)

	assert_eq(unit.hp, 10)
	assert_true(unit.is_alive())


func test_ダメージを受けるとHPが減る():
	var unit := Unit.new(Unit.Team.ENEMY, 10, 3)

	unit.take_damage(4)

	assert_eq(unit.hp, 6)


func test_HPが0になると死亡する():
	var unit := Unit.new(Unit.Team.ENEMY, 10, 3)

	unit.take_damage(10)

	assert_false(unit.is_alive())


func test_HPは0より小さくならない():
	var unit := Unit.new(Unit.Team.ENEMY, 10, 3)

	unit.take_damage(25)

	assert_eq(unit.hp, 0)


func test_ブロックがあるとダメージを先にブロックで受ける():
	var unit := Unit.new(Unit.Team.PLAYER, 10, 3)
	unit.gain_block(4)

	unit.take_damage(3)

	assert_eq(unit.hp, 10)
	assert_eq(unit.block, 1)


func test_ブロックを超えたぶんだけHPが減る():
	var unit := Unit.new(Unit.Team.PLAYER, 10, 3)
	unit.gain_block(4)

	unit.take_damage(6)

	assert_eq(unit.hp, 8)
	assert_eq(unit.block, 0)


func test_ブロックは重ねて得られる():
	var unit := Unit.new(Unit.Team.PLAYER, 10, 3)

	unit.gain_block(4)
	unit.gain_block(3)

	assert_eq(unit.block, 7)


func test_ダメージを受けると実際に減ったHPを返す():
	var unit := Unit.new(Unit.Team.PLAYER, 10, 3)
	unit.gain_block(4)

	assert_eq(unit.take_damage(6), 2)
	assert_eq(unit.take_damage(20), 8)
