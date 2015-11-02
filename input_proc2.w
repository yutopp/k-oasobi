x := 0;

begin
  proc p is (y := 100; x := y + 100);
  x := 10; call p
end
