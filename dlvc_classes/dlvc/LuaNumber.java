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

    @Override
    public boolean equals(Object o) {
        if (o instanceof LuaNumber) {
            LuaNumber ol = (LuaNumber) o;
            return Double.compare(this.number, ol.number) == 0;
        }
        return false;
    }

    public void print() {
        System.out.println(number);
    }

    public String toString() {
        return String.valueOf(number);
    }

    public boolean boolValue() {
        return true;
    }

    public LuaType negate() {
        return new LuaNumber(-number);
    }
}
