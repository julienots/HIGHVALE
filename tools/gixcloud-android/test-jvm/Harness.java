import com.gixcloud.app.*;
import java.io.File;
public class Harness {
  public static void main(String[] a) throws Exception {
    File d = new File(a[0]); d.mkdirs();
    android.content.Context ctx = new android.content.Context(d);
    Gix g = Gix.get(ctx);
    ctx.getSharedPreferences("gixcloud", 0).edit().putString("token", "testtoken").putInt("port", Integer.parseInt(a[1])).apply();
    McpHttpServer s = new McpHttpServer(g);
    s.start();
    System.out.println("READY " + g.tools.list().length());
    Thread.sleep(Long.MAX_VALUE);
  }
}
