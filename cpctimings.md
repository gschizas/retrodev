# Introducción #
El reloj principal del CPC va a 16 MHz, el cual esta conectado al Gate Array que genera las otras señales de reloj.

El Gate Array se encarga de las siguientes tareas:
  * Generar la señal de reloj de 1 MHz para el CRTC y el AY-3-8912.
  * Generar la señal de reloj de 4 MHz para el Z80.
  * Arbitrar el acceso a la RAM entre el Z80 y el hardware de vídeo (CRTC y Gate Array).

Por lo que tenemos que en cada microsegundo:
  * El CRTC genera una dirección de memoria usando sus señales de salida MA y RA.
  * El Gate Array suministra dos bytes por cada dirección.
  * La prioridad la tiene el hardware de vídeo, evitando cualquier posible interrupción en la generación de la imagen. Para ello el Gate Array activa su patilla "READY", la cual está conectada a la patilla "/WAIT" del Z80. Deteniendose todo el acceso de la CPU a la memoria mientras el hardware de vídeo la esté accediendo.

Como resultado de esto que comentábamos, en los ciclos de Máquina (M-ciclos) en los que se accede a memoria los T-estados se incrementan, haciendo la duración de todas las instrucciones múltiplos de 1 microsegundo, esto es lo que da en la practica una velocidad aparente del Z80 de 3.3Mhz.

Podríamos decir (aunque no es totalmente correcto en todos los casos) que los tiempos de las instrucciones en microsegundos son iguales a dividir el número de t-estados entre 4 y aproximar por exceso al siguiente entero.

# Tabla de tiempos de las instrucciones del Z80 #

A continuación vamos a poner una serie de tablas, agrupadas por tipos de instrucciones, con los **tiempos en microsegundos** de dichas instrucciones del Z80 en el CPC:

**Leyenda**
|cc|Código de condición (z, nz, c, nc, p, m, po y pe)|
|:-|:------------------------------------------------|
|r |Registro de 8 bits (B, C, D, E, H, L y A)        |
|b |Número de Bit (0, 1, 2, 3, 4, 5, 6 y 7)          |
|p |Salto de la instrucción RST (#00 - #38)          |
|n |Valor de 8 bits                                  |
|nnnn|Valor de 16 bits                                 |
|d |Desplazamiento de 8 bits                         |
|rp|Registro de 16 bits (HL, DE, BC y SP)            |
|nc|Condición no satisfecha                          |
|c |Condición satisfecha                             |

Nota: Los tiempos relativos al registro IY son idénticos a los del registro IX.

**Grupo de Carga de 8 Bits**
|1|2|3|4|5|6|
|:|:|:|:|:|:|
|LD r,r|LD r,(HL)|LD I,A|LD A,(nnnn)|LD r,(IX+d)|LD (IX+d),n|
| |LD (HL),r|LD A,I|LD (nnnn),A|LD (IX+d),r| |
| |LD r,IXH|LD R,A| | | |
| |LD r,IXL|LD A,R| | | |
| |LD IXH,r|LD IXH,n| | | |
| |LD IXL,r|LD IXL,n| | | |
| |LD r,n|LD (HL),n | | | |
| |LD A,(BC)| | | | |
| |LD (BC),A| | | | |
| |LD (DE),A| | | | |
| |LD A,(DE)| | | | |

**Grupo de Carga de 16 Bits**
|2|3|4|5|6|
|:|:|:|:|:|
|LD SP,HL|LD SP,IX|LD IX,nnnn|PUSH IX|prefijo ED + LD (nnnn),HL|
| |LD rp,nnnn|PUSH rp|PUSH IY|prefijo ED + LD HL,(nnnn)|
| |POP rp| |POP IX|LD (nnnn),IX|
| | | |POP IX|LD IX,(nnnn)|
| | | |LD HL,(nnnn)|LD (nnnn),rp|
| | | |LD (nnnn),HL|LD rp,(nnnn)|

**Grupo de Intercambio, Transferencia y Búsqueda de Bloques**
|1|4|5|4 (BC-1 == 0) : 6 (BC-1 <> 0)|5 (BC-1 == 0) : 6 (BC-1 <> 0)|6|7|
|:|:|:|:----------------------------|:----------------------------|:|:|
|EXX|CPI|LDI|CPIR                         |LDIR                         |EX (SP),HL|EX (SP),IX|
|EX AF,AF'|CPD|LDD|CPDR                         |LDDR                         | | |
|EX DE,HL| | |                             |                             | | |


**Grupo Aritmético de 8 Bits**
|1|2|3|5|6|
|:|:|:|:|:|
|INC r  |ADD A,(HL) |INC (HL) |ADD A,(IX+d) |INC (IX+d)|
|DEC r  |ADC A,(HL) |DEC (HL) |ADC A,(IX+d) |DEC (IX+d)|
|ADD A,r|SUB A,(HL) |         |SUB (IX+d)   | |
|ADC A,r|SBC A,(HL) |         |SBC A,(IX+d) | |
|SUB r  |ADD A,n    | | | |
|SBC A,r|ADC A,n    | | | |
|       |SUB n      | | | |
|       |SBC A,n    | | | |
|       |ADD A,IXH  | | | |
|       |ADC A,IXH  | | | |
|       |SUB IXH    | | | |
|       |SBC A,IXH  | | | |
|       |INC IXH    | | | |
|       |DEX IXH    | | | |
|       |INC IXL    | | | |
|       |DEC IXL    | | | |

**Grupo Aritmético de 16 Bits**
|2|3|4|
|:|:|:|
|INC rp |INC IX    |ADD IX,rp |
|DEC rp |DEC IX    |SBC HL,rp |
|       |ADD HL,rp |ADC HL,rp |

**Grupo Lógico de 8 Bits**
|1|2|5|
|:|:|:|
|AND r |AND IXH  |AND (IX+d) |
|XOR r |XOR IXH  |XOR (IX+d) |
|OR r  |OR IXH   |OR (IX+d)  |
|CP r  |CP IXH   |CP (IX+d)  |
| |AND (HL) | |
| |XOR (HL) | |
| |OR (HL)  | |
| |CP (HL)  | |
| |AND n    | |
| |XOR n    | |
| |OR n     | |
| |CP n     | |

**Grupo de Rotación y Desplazamiento**
|1|2|4|5|7|
|:|:|:|:|:|
|RLCA |RLC r |RLC (HL) |RLD |RLC (IX+d) |
|RRCA |RRC r |RRC (HL) |RRD |RRC (IX+d) |
|RLA  |RR r  |RR (HL)  | |RL (IX+d)  |
|RRA  |RL r  |RL (HL)  | |RR (IX+d)  |
| |SLA r |SLA (HL) | |SLA (IX+d) |
| |SLL r |SLL (HL) | |SRA (IX+d) |
| |SRL r |SRL (HL) | |SLL (IX+d) |
| | | | |SRL (IX+d) |
| | | | |RLC (IX+d),r |
| | | | |RRC (IX+d),r |
| | | | |RL (IX+d),r |
| | | | |RR (IX+d),r |
| | | | |SLA (IX+d),r |
| | | | |SRA (IX+d),r |
| | | | |SLL (IX+d),r |
| | | | |SRL (IX+d),r |

**Grupo de Manipulación de Bits**
|2|3|4|6|7|
|:|:|:|:|:|
|BIT b,r |BIT b,(HL) |RES b,(HL) |BIT b,(IX+d) |RES b,(IX+d) |
|RES b,r | |SET b,(HL) | |SET b,(IX+d) |
|SET b,r | | | |RES b,(IX+d),r |
| | | | |SET b,(IX+d),r |

**Grupo de Salto**
|1|2|2 (nc) : 3 (c)|3|3 (BC-1 == 0) : 4 (BC-1 <> 0)|
|:|:|:-------------|:|:----------------------------|
|JP (HL) |JP (IX) |JR cc,d       |JP nnnn |DJNZ d                       |
| | |              |JP cc,nnnn |                             |
| | |              |JR d |                             |

**Grupo de Llamada y Retorno**
|2 (nc) : 4 (c)|3|3 (nc) : 5 (c)|4|5|
|:-------------|:|:-------------|:|:|
|RET cc        |RET |CALL cc,nnnn  |RST p |CALL nnnn |
|              | |              |RETN | |
|              | |              |RETI | |

**Grupo de Entrada y Salida**
|3|4|5|5(BC-1=0):6(BC-1<>0)|
|:|:|:|:-------------------|
|IN A,(nn)  |IN r,(C)  |INI  |INIR                |
|OUT (nn),A |OUT (C),r |IND  |INDR                |
| |IN F,(C)  |OUTI |OTIR                |
| |OUT (C),0 |OUTD |OTDR                |

**Grupo de Control de la CPU**
|1|2|1-Variable (1)|
|:|:|:-------------|
|DI |NEG  |HALT          |
|EI |IM 0 |              |
|DAA |IM 1 |              |
|SCF |IM 2 |              |
|CCF |ED "NOP" (ED 00 - ED 3F) |              |
|CPL | |              |
|NOP | |              |
|prefijo DD (2) | |              |
|prefijo FD (2) | |              |

1: En el mejor de los casos son 5 microsegundos (HALT + Interrupción + EI + RET)

2: Estos tiempos se aplican cuando van seguidos varios prefijos DD ó FD.

# Notas adicionales #
## Sincronización con el haz de electrones ##
Si queremos sincronizar nuestro código con el haz de electrones del monitor, tenemos que saber que en pintar una línea tarda 64 microsegundos, con un refresco de 50Hz tenemos un máximo de 312 líneas por lo que podemos concluir que una pantalla completa se pintará en 19.968 microsegundos.

## Relativas a las interrupciones ##
Hay que notar que el tiempo entre la detección de una interrupción y su ejecución, es dependiente del modo de interrupciones en que nos encontremos, teniendo que en:
  * Modo 0: Depende de la instrucción.
  * Modo 1: 4 microsegundos (RST #38).
  * Modo 2: 5 microsegundos (CALL #iixx).

Aparte al comienzo de una interrupción, el Z80 fuerza 2 ciclos de espera (2 T-Estados) para la detección de la interrupción. Para la mayoría de los casos esto es correcto, pero no siempre es así. Aparentemente la instrucción que esta siendo ejecutada mientras ocurre una interrupción, puede provocar que uno de esos 2 ciclos de espera sea eliminado (solamente 1 ciclo de espera ó T-Estado).

Estas instrucciones son:
  * LD A,I
  * LD I,A
  * LD A,R
  * LD R,A
  * LD SP,HL
  * LD SP,IX
  * LD SP,IY
  * EX (SP),HL
  * EX (SP),IX
  * EX (SP),IY
  * INC ss   (ss = HL, BC, DE ó SP)
  * INC IX
  * INC IY
  * DEC ss   (ss = HL, BC, DE ó SP)
  * DEC IX
  * DEC IY
  * LDI (y ambos estados de LDIR)
  * LDD (y ambos estados de  LDDR)
  * CPIR (cuando está en looping)
  * CPDR (cuando está en looping)
  * RET cc (condición no cumplida)

Todo esto,  esta relacionado con una combinación de los t-Estados de la instrucción, los M-ciclos y los estados de espera impuestos por el hardware del CPC para forzar el que cada instrucción tenga una duración múltiplo de microsegundos; ya que si descomponemos los T-estados de las instrucciones en sus componentes y aplicamos las esperas introducidas por el Gate Array, observaremos que en los "huecos" (los hay de 1, 2 ó 3 T-estados) producidos por dichas esperas, durante los que el Z80 no puede acceder a memoria, pueden ser utilizados por éste para detectar que se ha producido una interrupción.