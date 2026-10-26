#lang eopl
;Autores: Santiago Alexander Criollo 2380661-3743

;; Taller 2 — El intérprete de Cauca.
;; Fachada: reúne los seis módulos de src/ y reexporta todo lo que
;; definen, de modo que quien la requiera vea todos los nombres sin
;; requerir los módulos uno por uno.
;;
;;   src/sintaxis.rkt    especificación léxica y gramatical, scanner, parser
;;   src/valores.rkt     el valor procedimiento
;;   src/ambiente.rkt    el TAD ambiente y el ambiente inicial
;;   src/primitivas.rkt  las primitivas y sus verificaciones
;;   src/interprete.rkt  la evaluación y la aplicación de procedimientos
;;   src/interfaz.rkt    el punto de entrada y el REPL
;;
;; Los require van en un solo sentido. Racket no carga dos módulos que se
;; requieran entre sí.

(require "src/sintaxis.rkt")
(require "src/valores.rkt")
(require "src/ambiente.rkt")
(require "src/primitivas.rkt")
(require "src/interprete.rkt")
(require "src/interfaz.rkt")

(provide (all-from-out "src/sintaxis.rkt"
                       "src/valores.rkt"
                       "src/ambiente.rkt"
                       "src/primitivas.rkt"
                       "src/interprete.rkt"
                       "src/interfaz.rkt"))

;;; ==========================================================
;;; Ejemplos
;;; ==========================================================

#|
  Ejemplos. Las pruebas con rackunit viven en pruebas-cauca.rkt.

  ---------------- Scanner ----------------
  (scanner "let a = 5 in +(a, -1.5) end")
    => '((literal-string47 "let" 1) (identificador a 1) (literal-string47 "=" 1)
         (numero 5 1) (literal-string47 "in" 1) (literal-string47 "+" 1)
         (literal-string47 "(" 1) (identificador a 1) (literal-string47 "," 1)
         (numero -1.5 1) (literal-string47 ")" 1) (literal-string47 "end" 1))

  (scanner "if true then 1 else 2 end")
    => '((literal-string47 "if" 1) (literal-string47 "true" 1)
         (literal-string47 "then" 1) (numero 1 1) (literal-string47 "else" 1)
         (numero 2 1) (literal-string47 "end" 1))

  (scanner "apply f (1, 2) // comentario")
    => '((literal-string47 "apply" 1) (identificador f 1) (literal-string47 "(" 1)
         (numero 1 1) (literal-string47 "," 1) (numero 2 1) (literal-string47 ")" 1))
    ; el comentario se ignora

  (scanner "aplicar-n")
    => '((identificador aplicar 1) (literal-string47 "-" 1) (identificador n 1))
    ; el guion no hace parte de un identificador

  (scanner "proc (x) x end")
    => '((literal-string47 "proc" 1) (literal-string47 "(" 1) (identificador x 1)
         (literal-string47 ")" 1) (identificador x 1) (literal-string47 "end" 1))

  ---------------- Parser ----------------
  (parser "5")
    => (a-program (lit-exp 5))
  (parser "+(1, 2)")
    => (a-program (prim-exp (sum-prim) (list (lit-exp 1) (lit-exp 2))))
  (parser "if true then 1 else 2 end")
    => (a-program (if-exp (true-exp) (lit-exp 1) (lit-exp 2)))
  (parser "let a = 1 in a end")
    => (a-program (let-exp '(a) (list (lit-exp 1)) (var-exp 'a)))
  (parser "apply f (1)")
    => (a-program (app-exp (var-exp 'f) (list (lit-exp 1))))

  ---------------- Ejecución: base ----------------
  (interpretar "+(1, 2, 3)")                          => 6
  (interpretar "-(10, 3)")                            => 7
  (interpretar "*(2, 3, 4)")                          => 24
  (interpretar "/(20, 4)")                            => 5
  (interpretar "add1(4)")                             => 5
  (interpretar "<=(2, 3)")                            => #t
  (interpretar "not(true)")                           => #f
  (interpretar "if >(n, m) then 1 else 2 end")        => 1
  (interpretar "let a = 2 b = 3 in *(a, b) end")      => 6
  (interpretar "let base = 8 altura = 5 in if and(>(base, 0), >(altura, 0)) then *(base, altura) else 0 end end") => 40
  (interpretar "if 1 then 2 else 3 end")              => error (condición no booleana)
  (interpretar "zzz")                                 => error (variable no ligada)

  ---------------- Ejecución: primitivas nuevas ----------------
  (interpretar "abs(-5)")                 => 5
  (interpretar "abs(-2.5)")               => 2.5
  (interpretar "abs(true)")               => error
  (interpretar "mcd(12, 18)")             => 6
  (interpretar "mcd(12, 18, 8)")          => 2
  (interpretar "mcd(4, 2.5)")             => error
  (interpretar "mcm(4, 6)")               => 12
  (interpretar "mcm(2, 3, 4)")            => 12
  (interpretar "mcm(true, 2)")            => error
  (interpretar "promedio(2, 4)")          => 3
  (interpretar "promedio(10)")            => 10
  (interpretar "promedio(1, true)")       => error
  (interpretar "xor(true, false)")        => #t
  (interpretar "xor(true, true)")         => #f
  (interpretar "xor(1, true)")            => error
  (interpretar "implica(true, false)")    => #f
  (interpretar "implica(false, true)")    => #t
  (interpretar "implica(true, 1)")        => error
  (interpretar "entre(5, 1, 10)")         => #t
  (interpretar "entre(11, 1, 10)")        => #f
  (interpretar "entre(true, 1, 2)")       => error

  ---------------- Ejecución: procedimientos ----------------
  (interpretar "let f = proc () 7 end in apply f () end")                                  => 7
  (interpretar "let f = proc (x) add1(x) end in apply f (4) end")                          => 5
  (interpretar "let f = proc (a, b, c) +(a, b, c) end in apply f (1, 2, 3) end")           => 6
  (interpretar "let aplicar = proc (g, v) apply g (v) end in let doble = proc (x) *(x, 2) end in apply aplicar (doble, 5) end end") => 10
  (interpretar "let sumador = proc (a) proc (b) +(a, b) end end in let suma3 = apply sumador (3) in apply suma3 (4) end end")       => 7
  (interpretar "let factor = 10 in let escalar = proc (v) *(v, factor) end in let factor = 1000 in apply escalar (5) end end end") => 50
  (interpretar "apply 5 (1)")                                                              => error (operador no es procedimiento)
  (interpretar "let f = proc (x) x end in apply f (1, 2) end")                             => error (cantidad de argumentos)

  ---------------- Ejecución: recursión y case ----------------
  (interpretar "letrec fact (n) = if ==(n, 0) then 1 else *(n, apply fact (sub1(n))) end in apply fact (5) end") => 120
  (interpretar "letrec potencia (base, exp) = if ==(exp, 0) then 1 else *(base, apply potencia (base, sub1(exp))) end in apply potencia (2, 10) end") => 1024
  (interpretar "letrec par (k) = if ==(k, 0) then true else apply impar (sub1(k)) end impar (k) = if ==(k, 0) then false else apply par (sub1(k)) end in apply par (10) end") => #t
  (interpretar "letrec iterar (f, x, k) = if ==(k, 0) then x else apply iterar (f, apply f (x), sub1(k)) end in apply iterar (proc (z) *(z, 2) end, 1, 5) end") => 32
  (interpretar "let dia = 3 in case dia of 1 => 100 of 3 => 300 of 7 => 700 otherwise => 0 end end") => 300
  (interpretar "case 9 of 1 => 1 otherwise => 99 end")                                     => 99
  (interpretar "case true of 1 => 1 otherwise => 0 end")                                   => error (control no numérico)
|#
