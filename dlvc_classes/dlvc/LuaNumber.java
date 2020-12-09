package dlvc;

public class LuaNumber implements LuaType {
    protected Double number;

    public LuaNumber(double n) {
        number = n;
    }

    @Override
    public int hashCode() {
       return number.hashCode(); 
    }

    public void print() {
        System.out.println(number);
    }

    public String toString() {
        return String.valueOf(number);
    }
}
