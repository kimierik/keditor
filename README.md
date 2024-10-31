Learning to try to make a text editor


for some reason zls does not understand macros propperly
so it will complain that TextToFloat function is not defined
it is and the program will compile fine
if you want to remove this error you must define it under the end of the standalone ifcheck

```c
#endif      // RAYGUI_STANDALONE
float TextToFloat(const char *text);         // Get float value from text
```
