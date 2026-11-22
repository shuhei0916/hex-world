import arc.struct.Seq;
import mindustry.Vars;
import mindustry.content.TechTree;
import mindustry.content.TechTree.TechNode;
import mindustry.core.ContentLoader;
import mindustry.ctype.UnlockableContent;
import mindustry.type.*;
import mindustry.world.Block;
import mindustry.world.blocks.production.GenericCrafter;
import mindustry.world.consumers.*;

import java.io.*;
import java.nio.charset.StandardCharsets;

/** Mindustry の基本コンテンツを読み込み、アイテム・ブロック・研究ツリーを JSON で書き出す。 */
public class MindustryDump {
    static StringBuilder sb = new StringBuilder();

    static String q(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n") + "\"";
    }

    static String stacks(ItemStack[] st) {
        StringBuilder b = new StringBuilder("[");
        if (st != null) for (int i = 0; i < st.length; i++) {
            if (i > 0) b.append(",");
            b.append("[").append(q(st[i].item.name)).append(",").append(st[i].amount).append("]");
        }
        return b.append("]").toString();
    }

    static String lstacks(LiquidStack[] st) {
        StringBuilder b = new StringBuilder("[");
        if (st != null) for (int i = 0; i < st.length; i++) {
            if (i > 0) b.append(",");
            b.append("[").append(q(st[i].liquid.name)).append(",").append(st[i].amount).append("]");
        }
        return b.append("]").toString();
    }

    static String consumes(Block b) {
        StringBuilder items = new StringBuilder("[]"), liquids = new StringBuilder("[]");
        float power = 0;
        for (Consume c : b.consumers) {
            if (c instanceof ConsumeItems ci) items = new StringBuilder(stacks(ci.items));
            else if (c instanceof ConsumeLiquid cl) liquids = new StringBuilder("[[" + q(cl.liquid.name) + "," + cl.amount + "]]");
            else if (c instanceof ConsumeLiquids cls) liquids = new StringBuilder(lstacks(cls.liquids));
            else if (c instanceof ConsumePower cp) power = cp.usage;
        }
        return "\"inItems\":" + items + ",\"inLiquids\":" + liquids + ",\"power\":" + power;
    }

    static void node(TechNode n, String parent, boolean first) {
        if (!first) sb.append(",\n");
        StringBuilder objs = new StringBuilder("[");
        for (int i = 0; i < n.objectives.size; i++) {
            if (i > 0) objs.append(",");
            objs.append(q(n.objectives.get(i).getClass().getSimpleName() + ":" + n.objectives.get(i).toString()));
        }
        objs.append("]");
        sb.append("{\"name\":").append(q(n.content.name)).append(",\"type\":").append(q(n.content.getContentType().name()))
          .append(",\"parent\":").append(q(parent)).append(",\"req\":").append(stacks(n.requirements))
          .append(",\"objectives\":").append(objs).append("}");
        for (TechNode c : n.children) node(c, n.content.name, false);
    }

    public static void main(String[] args) throws Exception {
        Vars.headless = true;
        arc.Core.settings = new arc.Settings();  // 空のまま使う（ユーザーの設定ファイルは読まない）
        Vars.content = new ContentLoader();
        Vars.content.createBaseContent();
        Vars.content.init();

        sb.append("{\"items\":[\n");
        boolean first = true;
        for (Item it : Vars.content.items()) {
            if (!first) sb.append(",\n");
            first = false;
            sb.append("{\"name\":").append(q(it.name)).append(",\"hardness\":").append(it.hardness)
              .append(",\"cost\":").append(it.cost).append(",\"buildable\":").append(it.buildable).append("}");
        }
        sb.append("],\"liquids\":[\n");
        first = true;
        for (Liquid l : Vars.content.liquids()) {
            if (!first) sb.append(",\n");
            first = false;
            sb.append("{\"name\":").append(q(l.name)).append(",\"gas\":").append(l.gas).append("}");
        }
        // 地面・鉱脈・壁から直接採れるもの（加工の段階を数えるときの原料）
        java.util.TreeSet<String> raw = new java.util.TreeSet<>();
        for (Block b : Vars.content.blocks()) {
            if (b.itemDrop != null) raw.add(b.itemDrop.name);
            if (b instanceof mindustry.world.blocks.environment.Floor f) {
                if (f.liquidDrop != null) raw.add(f.liquidDrop.name);
                if (f.wallOre && f.itemDrop != null) raw.add(f.itemDrop.name);
            }
        }
        sb.append("],\"raw\":[");
        first = true;
        for (String r : raw) {
            sb.append(first ? "" : ",").append(q(r));
            first = false;
        }
        sb.append("],\"blocks\":[\n");
        first = true;
        for (Block b : Vars.content.blocks()) {
            if (b.buildVisibility == mindustry.world.meta.BuildVisibility.hidden && !(b instanceof GenericCrafter)) continue;
            if (!first) sb.append(",\n");
            first = false;
            sb.append("{\"name\":").append(q(b.name)).append(",\"class\":").append(q(b.getClass().getSimpleName()))
              .append(",\"category\":").append(q(b.category.name())).append(",\"size\":").append(b.size)
              .append(",\"visible\":").append(b.buildVisibility != mindustry.world.meta.BuildVisibility.hidden)
              .append(",\"env\":").append(b.envEnabled)
              .append(",\"requirements\":").append(stacks(b.requirements)).append(",").append(consumes(b));
            if (b instanceof GenericCrafter g) {
                sb.append(",\"craftTime\":").append(g.craftTime)
                  .append(",\"outItems\":").append(stacks(g.outputItems))
                  .append(",\"outLiquids\":").append(lstacks(g.outputLiquids));
            }
            sb.append("}");
        }
        sb.append("],\"tech\":[\n");
        first = true;
        for (TechNode root : TechTree.roots) {
            sb.append(first ? "" : ",\n").append("{\"root\":").append(q(root.name)).append(",\"nodes\":[\n");
            first = false;
            node(root, null, true);
            sb.append("]}");
        }
        sb.append("]}\n");
        try (Writer w = new OutputStreamWriter(new FileOutputStream(args[0]), StandardCharsets.UTF_8)) {
            w.write(sb.toString());
        }
        System.out.println("ok");
    }
}
