package android.content;
import java.io.File;
import java.util.*;
public class Context {
  public static final int MODE_PRIVATE = 0;
  final File dir; final Map<String, SharedPreferences> prefs = new HashMap<>();
  public Context(File dir) { this.dir = dir; }
  public Context getApplicationContext() { return this; }
  public File getFilesDir() { return dir; }
  public SharedPreferences getSharedPreferences(String n, int m) { return prefs.computeIfAbsent(n, k -> new MemPrefs()); }
  public Object getPackageManager() { throw new UnsupportedOperationException("PackageManager absent (test JVM)"); }
  static class MemPrefs implements SharedPreferences {
    final Map<String,Object> m = new HashMap<>();
    public boolean contains(String k){return m.containsKey(k);}
    public String getString(String k,String d){return (String)m.getOrDefault(k,d);}
    public int getInt(String k,int d){return (Integer)m.getOrDefault(k,d);}
    public boolean getBoolean(String k,boolean d){return (Boolean)m.getOrDefault(k,d);}
    public Editor edit(){ return new Editor(){
      public Editor putString(String k,String v){m.put(k,v);return this;}
      public Editor putInt(String k,int v){m.put(k,v);return this;}
      public Editor putBoolean(String k,boolean v){m.put(k,v);return this;}
      public void apply(){} public boolean commit(){return true;} }; }
  }
}
