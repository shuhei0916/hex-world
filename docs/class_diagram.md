# Class Diagram

現在のプロジェクト（Hex World）のクラス構造と関係性を示します。

```mermaid
classDiagram
    %% --- Core Components ---
    class Main {
        +GridManager grid_manager
        +Palette palette
        +PiecePlacer piece_placer
        +HUD hud
        +_ready()
    }

    class GridManager {
        -_registered_hexes: Dictionary
        -_occupied_hexes: Dictionary
        -_hex_to_piece_map: Dictionary
        +Layout layout
        +place_piece(shape: Array, hex: Hex, color: Color, type: int)
        +remove_piece_at(hex: Hex)
        +can_place(shape: Array, hex: Hex) : bool
        +hex_to_pixel(hex: Hex) : Vector2
    }

    class PiecePlacer {
        +GridManager grid_manager
        +Palette palette
        +current_piece_shape: Array
        +place_current_piece() : bool
        +remove_piece_at_hex(hex: Hex) : bool
        +rotate_current_piece()
        +_update_preview()
    }

    class Palette {
        -_slots: Dictionary
        +active_slot_index: int
        +get_piece_data_for_slot(index: int) : Dictionary
        +select_slot(index: int)
    }

    %% --- Entities & Data ---
    class Piece {
        +piece_type: int
        +hex_coordinates: Array~Hex~
        +setup(data: Dictionary)
    }

    class HexTile {
        +hex_coordinate: Hex
        +setup_hex(hex: Hex)
        +set_color(color: Color)
        +set_highlight(active: bool)
    }
    
    class TetrahexShapes {
        <<static>>
        +definitions: Dictionary
        +TetrahexType: enum
    }

    %% --- Relationships ---
    %% Composition / Aggregation
    Main *-- GridManager
    Main *-- PiecePlacer
    Main *-- Palette
    
    %% Dependency / Usage
    PiecePlacer --> GridManager : "配置・削除を依頼 (Uses)"
    PiecePlacer --> Palette : "選択中の形状を取得 (Uses)"
    
    %% Management
    GridManager o-- Piece : "生成・保持 (Instantiates & Stores)"
    GridManager o-- HexTile : "生成・保持 (Instantiates & Stores)"
    
    %% Type Reference
    Piece ..> TetrahexShapes : "Type IDを参照"
    Palette ..> TetrahexShapes : "形状データを参照"
```

## クラスの責務概要

### Main
ゲームのエントリーポイント。
各コンポーネント（GridManager, Palette, PiecePlacer）を保持し、それらの依存関係を注入（Setup）する役割を担います。また、トップレベルの入力イベント（数字キーなど）の一部を処理します。

### GridManager
**盤面の管理者**。
- **論理**: どのHexがグリッド内か、どのHexが埋まっているか、どこにどのPieceがあるかを管理します。
- **配置**: `place_piece` で `Piece` ノードを生成し、配置します。
- **削除**: `remove_piece_at` で `Piece` ノードを削除します。
- **視覚**: `HexTile` を生成し、グリッドを描画します。

### PiecePlacer
**配置操作のコントローラー**。
- ユーザーの入力（マウス移動、クリック）を監視し、プレビュー（マウス追従、スナップ）を表示します。
- 配置が可能か `GridManager` に問い合わせ、可能であれば配置を依頼します。
- 「どこに置こうとしているか」を管理し、「実際に置く」のは `GridManager` に任せます。

### Palette / PaletteUI
**手持ちの駒（形状）の管理者**。
- どのスロットにどの形状（TetrahexType）が割り当てられているかを管理します。
- 選択中のスロット状態を管理します。

### Piece
**配置されたオブジェクトの実体**。
- シーン上に存在する `Node2D` です。
- 自身の種類（`piece_type`）や、占有しているHex座標（`hex_coordinates`）を保持します。
- 今後、インベントリや稼働状態などのロジックはここに追加されます。
