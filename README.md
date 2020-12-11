# Compilador de Lua
Trabalho da matéria de Compiladores 2020/1 (EARTE) UFES.

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/DanfsAC/DLV_compiler)
![Source Language](https://img.shields.io/static/v1?label=source-lang&message=Lua&color=blueviolet)
![Target Architecture](https://img.shields.io/static/v1?label=target-arch&message=JVM&color=blue)
![JVM Assembler](https://img.shields.io/static/v1?label=assembler&message=Jasmin&color=red)

## Instruções
### Compilação
```bash
$ make
```

### Compilação do run time
```bash
$ ant
```

### Execução dos Testes
```bash
$ ./run_tests.sh
```

## Features Implementadas

## IO
### print
```lua
print(foo)
print(1)
print("abc")
```

### read
```lua
local foo = read() -- read stdin
```

### Operadores
#### Aritméticos
```lua
print( 2  +  2 )  -- 4
print("2" -  2 )  -- 0
print( 2  / "2")  -- 1
print("2" * "2")  -- 4
print( 2  //  2 ) -- 1
print( 2  % "2")  -- 0
print("2" ^  2 )  -- 4
print(- "2")      -- -2
```

#### Relacionais
```lua
print( 2  >  1 )  -- true
print("2" >= "1") -- true
print( 2  <=  1 ) -- false
print("2" < "1")  -- false
print({}  ==  {}) -- false
print("2" ~=  {}) -- true
```

#### Lógicos
```lua
print( 2  or "1")  -- 2
print("2" and "1") -- "1"
print( not true )  -- false
```

#### Bitwise
```lua
print(~  2 )     -- -3 (NOT)
print( 2  | "1") --  3 (OR)
print("2" &  1 ) --  0 (AND)
print( 2  ~ "2") --  0 (XOR)
print(2  << "1") --  4 (left shift)
print(2  >>  1 ) --  1 (right shift)
```

#### Concatenação
```lua
print("Hewwo" .. " oworld") -- "Hewwo oworld"
print("2" ..  1 ) -- 21
print( 2  ..  1 ) -- 21
```

#### Tamanho
```lua
print(#{1,2,3}) -- 3
print(#"Compiladores")   -- 12
```


#
### Laços de loop
#### Repeat ... until
```lua
function digitProduct(n)
  if n == 0 then
      return 0
  end
  
  local prod = 1
  
  repeat
      prod = prod * (n % 10)
      n = n // 10
  until n == 0
  
  return prod
end

print(digitProduct(12345)) -- 120
```

#### For
```lua
function fibonacci(n)
  local a,b = 0,1
  
  for i = 1,n-1 do
      a,b = b, a+b
  end
  
  return a
end

print(fibonacci(9)) -- 21
```

### Recursão
```lua
function collatz_seq(n)
  if n <= 1 then
      return n
  else
      return n .. ", " .. collatz_seq(n % 2 == 0 and n/2 or 3*n+1)
  end
end

print(collatz_seq(5)) -- 5, 16, 8, 4, 2, 1
```


## Limitações

### Retorno de função
As funções podem apenas retornar um argumento

### Break
Break não é suportado

### Funções lambda e closures
Não são suportados

### Print
A função `print` aceita apenas um argumento

### For
O passo do loop deve ser positivo



## Integrantes
- [Daniel Silva](https://github.com/DanfsAC)
- [Luciano Henrique](https://github.com/luchenps)
- [Vinícius Lucas](https://github.com/VLRTroll)
