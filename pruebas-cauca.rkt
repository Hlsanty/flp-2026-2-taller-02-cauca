#lang eopl
;Autores: Santiago Alexander Criollo 2380661-3743

;; Taller 2 — El intérprete de Cauca.
;; Batería de pruebas con rackunit. Llega escrita en el fork y no se
;; modifica: las pruebas del grupo se agregan después, en suites nuevas
;; que se suman a la cuenta de fallidas del final.
;;
;; Requiere solamente la fachada, nunca un módulo de src/ por separado.
;;
;; Se ejecuta con:  racket pruebas-cauca.rkt

(require rackunit)
(require rackunit/text-ui)
(require (only-in racket/base exn:fail?))
(require "interprete-cauca.rkt")

;; corre : string -> valor
(define corre (lambda (texto) (interpretar texto)))

(define base
  (test-suite
   "Parte 1: interprete base"
   (test-case "literales y variables del ambiente inicial"
              (check-equal? (corre "42") 42)
              (check-equal? (corre "-7") -7)
              (check-equal? (corre "3.5") 3.5)
              (check-equal? (corre "n") 10)
              (check-equal? (corre "r") 5))
   (test-case "booleanos"
              (check-equal? (corre "true") #t)
              (check-equal? (corre "false") #f))
   (test-case "primitivas aritmeticas n-arias"
              (check-equal? (corre "+(1, 2, 3)") 6)
              (check-equal? (corre "-(10, 3, 2)") 5)
              (check-equal? (corre "*(2, 3, 4)") 24)
              (check-equal? (corre "/(100, 5, 2)") 10))
   (test-case "primitivas unarias"
              (check-equal? (corre "add1(n)") 11)
              (check-equal? (corre "sub1(n)") 9)
              (check-equal? (corre "not(true)") #f))
   (test-case "primitivas relacionales"
              (check-equal? (corre ">(n, m)") #t)
              (check-equal? (corre ">=(m, m)") #t)
              (check-equal? (corre "<(q, r)") #t)
              (check-equal? (corre "<=(r, q)") #f)
              (check-equal? (corre "==(n, 10)") #t))
   (test-case "primitivas booleanas binarias"
              (check-equal? (corre "and(true, false)") #f)
              (check-equal? (corre "or(true, false)") #t))
   (test-case "condicional"
              (check-equal? (corre "if >(n, m) then n else m end") 10)
              (check-equal? (corre "if <(n, m) then n else m end") 3))
   (test-case "ligaduras locales"
              (check-equal? (corre "let x = 2 y = 3 in *(x, y) end") 6)
              (check-equal? (corre "let x = 1 in let x = 2 in x end end") 2)
              (check-equal? (corre "let x = 1 in +(x, n) end") 11))
   (test-case "el ejemplo del area del rectangulo"
              (check-equal? (corre "// el area de un rectangulo, con el condicional que valida los lados
let base = 8
    altura = 5
in
  if and(>(base, 0), >(altura, 0))
  then *(base, altura)
  else 0
  end
end") 40))
   (test-case "la condicion del if debe ser booleana"
              (check-exn exn:fail? (lambda () (corre "if n then 1 else 2 end"))))
   (test-case "una variable no ligada es un error"
              (check-exn exn:fail? (lambda () (corre "z"))))
   (test-case "los comentarios se ignoran"
              (check-equal? (corre "// esto no cuenta
7") 7))))

(define primitivas-nuevas
  (test-suite
   "Parte 2: primitivas nuevas"
   (test-case "abs"
              (check-equal? (corre "abs(-7)") 7)
              (check-equal? (corre "abs(7)") 7)
              (check-equal? (corre "abs(-3.5)") 3.5))
   (test-case "mcd"
              (check-equal? (corre "mcd(12, 18)") 6)
              (check-equal? (corre "mcd(7, 13)") 1)
              (check-equal? (corre "mcd(12, 18, 24)") 6))
   (test-case "mcm"
              (check-equal? (corre "mcm(4, 6)") 12)
              (check-equal? (corre "mcm(3, 5)") 15)
              (check-equal? (corre "mcm(2, 3, 4)") 12))
   (test-case "promedio"
              (check-equal? (corre "promedio(1, 2, 3, 4)") 5/2)
              (check-equal? (corre "promedio(10)") 10)
              (check-equal? (corre "promedio(n, m)") 13/2))
   (test-case "xor"
              (check-equal? (corre "xor(true, false)") #t)
              (check-equal? (corre "xor(true, true)") #f)
              (check-equal? (corre "xor(false, false)") #f))
   (test-case "implica"
              (check-equal? (corre "implica(true, false)") #f)
              (check-equal? (corre "implica(false, false)") #t)
              (check-equal? (corre "implica(true, true)") #t))
   (test-case "entre"
              (check-equal? (corre "entre(5, 1, 10)") #t)
              (check-equal? (corre "entre(1, 1, 10)") #t)
              (check-equal? (corre "entre(11, 1, 10)") #f))
   (test-case "las primitivas verifican el tipo de sus argumentos"
              (check-exn exn:fail? (lambda () (corre "mcd(1.5, 2)")))
              (check-exn exn:fail? (lambda () (corre "xor(1, true)")))
              (check-exn exn:fail? (lambda () (corre "abs(true)")))
              (check-exn exn:fail? (lambda () (corre "entre(1, 2)"))))))

(define procedimientos
  (test-suite
   "Parte 3: procedimientos y clausuras"
   (test-case "procedimiento de un parametro"
              (check-equal? (corre "let escalar = proc (v) *(v, 2) end
                                    in apply escalar (21) end") 42))
   (test-case "procedimiento sin parametros"
              (check-equal? (corre "let f = proc () 7 end in apply f () end") 7))
   (test-case "procedimiento de varios parametros"
              (check-equal? (corre "let f = proc (a, b, c) +(a, b, c) end
                                    in apply f (1, 2, 3) end") 6))
   (test-case "un procedimiento recibe otro como argumento"
              (check-equal? (corre "let aplicardos = proc (f, x) apply f (apply f (x)) end
                                        doble = proc (v) *(v, 2) end
                                    in apply aplicardos (doble, 5) end") 20))
   (test-case "un procedimiento retorna otro procedimiento"
              ;; el resultado de una aplicacion se liga antes de volver a
              ;; aplicarlo: <expresion> no puede empezar con parentesis
              (check-equal? (corre "let sumador = proc (a) proc (b) +(a, b) end end
                                    in let suma3 = apply sumador (3)
                                       in apply suma3 (4) end
                                    end") 7))
   (test-case "el cuerpo se evalua en el ambiente de la definicion"
              (check-equal? (corre "let factor = 10
in
  let escalar = proc (v) *(v, factor) end
  in
    let factor = 1000
    in
      apply escalar (5)
    end
  end
end") 50))
   (test-case "aplicar algo que no es procedimiento es un error"
              (check-exn exn:fail? (lambda () (corre "apply 5 (1)"))))
   (test-case "la cantidad de argumentos debe coincidir"
              (check-exn exn:fail?
                         (lambda () (corre "let f = proc (a, b) +(a, b) end
                                            in apply f (1) end"))))))

(define recursion-y-case
  (test-suite
   "Parte 4: recursion y seleccion por valor"
   (test-case "el ejemplo de potencia"
              (check-equal? (corre "letrec
  potencia (base, exp) = if ==(exp, 0)
                         then 1
                         else *(base, apply potencia (base, sub1(exp)))
                         end
in
  apply potencia (2, 10)
end") 1024))
   (test-case "recursion simple"
              (check-equal? (corre "letrec
  factorial (n) = if ==(n, 0) then 1 else *(n, apply factorial (sub1(n))) end
in apply factorial (5) end") 120))
   (test-case "recursion mutua en el mismo letrec"
              (check-equal? (corre "letrec
  par? (n) = if ==(n, 0) then true else apply impar? (sub1(n)) end
  impar? (n) = if ==(n, 0) then false else apply par? (sub1(n)) end
in apply par? (10) end") #t)
              (check-equal? (corre "letrec
  par? (n) = if ==(n, 0) then true else apply impar? (sub1(n)) end
  impar? (n) = if ==(n, 0) then false else apply par? (sub1(n)) end
in apply impar? (7) end") #t))
   (test-case "letrec con un procedimiento pasado como argumento"
              (check-equal? (corre "letrec
  aplicarn (f, x, veces) = if ==(veces, 0)
                           then x
                           else apply f (apply aplicarn (f, x, sub1(veces)))
                           end
in let doble = proc (v) *(v, 2) end
   in apply aplicarn (doble, 1, 5) end
end") 32))
   (test-case "el ejemplo de case"
              (check-equal? (corre "let dia = 3
in
  case dia
    of 1 => 100
    of 3 => 300
    of 7 => 700
    otherwise => 0
  end
end") 300))
   (test-case "case con la rama otherwise activa"
              (check-equal? (corre "let dia = 5
in case dia of 1 => 100 of 3 => 300 otherwise => 0 end end") 0))
   (test-case "case evalua la expresion de control una sola vez"
              (check-equal? (corre "case +(1, 2) of 2 => 20 of 3 => 30 otherwise => 0 end") 30))
   (test-case "el control de case debe ser numero"
              (check-exn exn:fail?
                         (lambda () (corre "case true of 1 => 1 otherwise => 0 end"))))))

;; Las suites que agregue el grupo se declaran arriba y se suman aquí.

(define fallidas
  (+ (run-tests base)
     (run-tests primitivas-nuevas)
     (run-tests procedimientos)
     (run-tests recursion-y-case)))

(eopl:printf "~%==========================================~%")
(eopl:printf "  pruebas fallidas en total: ~s~%" fallidas)
(eopl:printf "==========================================~%")


;;; ==========================================================
;;; Pruebas del grupo
;;; ==========================================================

(require rackunit)
(require rackunit/text-ui)

;; ejecutar-ok : string x valor -> void
;; Evalúa el programa con interpretar y comprueba que dé el valor esperado.
(define ejecutar-ok
  (lambda (texto esperado)
    (check-equal? (interpretar texto) esperado texto)))

;; ejecutar-error : string -> void
;; Comprueba que evaluar el programa levante un error.
(define ejecutar-error
  (lambda (texto)
    (check-exn exn:fail? (lambda () (interpretar texto)))))

;; raiz : string -> expresion
;; Parsea el programa y retorna la expresión que lo compone.
(define raiz
  (lambda (texto)
    (cases programa (parser texto)
      (a-program (exp) exp))))

(define suite-taller-extra
  (test-suite "Pruebas del grupo"

    (test-case "scanner"
      (check-true (list? (scanner "let a = 5 in a end")))
      (check-equal? (scanner "1 // comentario\n 2") (scanner "1 2"))
      (check-equal? (scanner "  +(1,   2)  ") (scanner "+(1,2)"))
      (check-equal? (scanner "aplicar-n") (scanner "aplicar -n"))
      (check-not-equal? (scanner "-5") (scanner "5"))
      (check-not-equal? (scanner "3.5") (scanner "3"))
      (check-not-equal? (scanner "abc") (scanner "abd")))

    (test-case "parser"
      (check-true (programa? (parser "5")))
      (check-true (cases expresion (raiz "5") (lit-exp (d) (= d 5)) (else #f)))
      (check-true (cases expresion (raiz "x") (var-exp (id) (eqv? id 'x)) (else #f)))
      (check-true (cases expresion (raiz "true") (true-exp () #t) (else #f)))
      (check-true (cases expresion (raiz "+(1, 2)")
                    (prim-exp (prim rands) (= (length rands) 2)) (else #f)))
      (check-true (cases expresion (raiz "if true then 1 else 2 end")
                    (if-exp (t a b) #t) (else #f)))
      (check-true (cases expresion (raiz "let a = 1 b = 2 in a end")
                    (let-exp (ids rands body) (equal? ids '(a b))) (else #f)))
      (check-true (cases expresion (raiz "proc (x, y) x end")
                    (proc-exp (ids body) (equal? ids '(x y))) (else #f)))
      (check-true (cases expresion (raiz "apply f (1)")
                    (app-exp (rator rands) (= (length rands) 1)) (else #f)))
      (check-true (cases expresion (raiz "letrec f (x) = x in 1 end")
                    (letrec-exp (names idss bodies body) (equal? names '(f))) (else #f)))
      (check-true (cases expresion (raiz "case 1 of 1 => 2 otherwise => 3 end")
                    (case-exp (c vs as d) (equal? vs '(1))) (else #f)))
      (check-exn exn:fail? (lambda () (parser "if true then 1 end"))))

    (test-case "ambiente"
      (check-equal? (apply-env (ambiente-inicial) 'q) 2)
      (check-equal? (apply-env (ambiente-extendido '(a) '(1)
                                (ambiente-extendido '(a) '(2) (ambiente-vacio))) 'a) 1)
      (check-exn exn:fail? (lambda () (apply-env (ambiente-vacio) 'zzz))))

    (test-case "parte 1: base"
      (ejecutar-ok "5" 5)
      (ejecutar-ok "n" 10)
      (ejecutar-ok "true" #t)
      (ejecutar-ok "false" #f)
      (ejecutar-ok "+(1, 2, 3)" 6)
      (ejecutar-ok "-(10, 3)" 7)
      (ejecutar-ok "*(2, 3, 4)" 24)
      (ejecutar-ok "/(20, 4)" 5)
      (ejecutar-ok "+(1.5, 2.5)" 4.0)
      (ejecutar-ok "add1(4)" 5)
      (ejecutar-ok "sub1(4)" 3)
      (ejecutar-ok ">(3, 2)" #t)
      (ejecutar-ok ">=(2, 2)" #t)
      (ejecutar-ok "<(3, 2)" #f)
      (ejecutar-ok "<=(2, 3)" #t)
      (ejecutar-ok "==(4, 4)" #t)
      (ejecutar-ok "not(true)" #f)
      (ejecutar-ok "and(true, false)" #f)
      (ejecutar-ok "or(false, true)" #t)
      (ejecutar-ok "if >(n, m) then 1 else 2 end" 1)
      (ejecutar-ok "let a = 2 b = 3 in *(a, b) end" 6)
      (ejecutar-ok "let n = 1 in n end" 1)
      (ejecutar-ok "let base = 8 altura = 5 in if and(>(base, 0), >(altura, 0)) then *(base, altura) else 0 end end" 40))

    (test-case "parte 2: primitivas nuevas"
      (ejecutar-ok "abs(-5)" 5)
      (ejecutar-ok "abs(3)" 3)
      (ejecutar-ok "abs(-2.5)" 2.5)
      (ejecutar-ok "mcd(12, 18)" 6)
      (ejecutar-ok "mcd(12, 18, 8)" 2)
      (ejecutar-ok "mcd(7, 5)" 1)
      (ejecutar-ok "mcm(4, 6)" 12)
      (ejecutar-ok "mcm(2, 3, 4)" 12)
      (ejecutar-ok "mcm(5, 5)" 5)
      (ejecutar-ok "promedio(2, 4)" 3)
      (ejecutar-ok "promedio(10)" 10)
      (ejecutar-ok "promedio(1, 2, 3, 6)" 3)
      (ejecutar-ok "xor(true, false)" #t)
      (ejecutar-ok "xor(true, true)" #f)
      (ejecutar-ok "xor(false, false)" #f)
      (ejecutar-ok "implica(true, false)" #f)
      (ejecutar-ok "implica(false, true)" #t)
      (ejecutar-ok "implica(false, false)" #t)
      (ejecutar-ok "entre(5, 1, 10)" #t)
      (ejecutar-ok "entre(1, 1, 10)" #t)
      (ejecutar-ok "entre(11, 1, 10)" #f)
      (ejecutar-error "abs(true)")
      (ejecutar-error "mcd(4, 2.5)")
      (ejecutar-error "mcm(true, 2)")
      (ejecutar-error "promedio(1, true)")
      (ejecutar-error "xor(1, true)")
      (ejecutar-error "implica(true, 1)")
      (ejecutar-error "entre(true, 1, 2)"))

    (test-case "parte 3: procedimientos y clausuras"
      (ejecutar-ok "let f = proc () 7 end in apply f () end" 7)
      (ejecutar-ok "let f = proc (x) add1(x) end in apply f (4) end" 5)
      (ejecutar-ok "let f = proc (a, b, c) +(a, b, c) end in apply f (1, 2, 3) end" 6)
      (ejecutar-ok "let aplicar = proc (g, v) apply g (v) end in let doble = proc (x) *(x, 2) end in apply aplicar (doble, 5) end end" 10)
      (ejecutar-ok "let sumador = proc (a) proc (b) +(a, b) end end in let suma3 = apply sumador (3) in apply suma3 (4) end end" 7)
      (ejecutar-ok "let factor = 10 in let escalar = proc (v) *(v, factor) end in let factor = 1000 in apply escalar (5) end end end" 50))

    (test-case "parte 4: letrec y case"
      (ejecutar-ok "letrec fact (n) = if ==(n, 0) then 1 else *(n, apply fact (sub1(n))) end in apply fact (5) end" 120)
      (ejecutar-ok "letrec potencia (base, exp) = if ==(exp, 0) then 1 else *(base, apply potencia (base, sub1(exp))) end in apply potencia (2, 10) end" 1024)
      (ejecutar-ok "letrec par (k) = if ==(k, 0) then true else apply impar (sub1(k)) end impar (k) = if ==(k, 0) then false else apply par (sub1(k)) end in apply par (10) end" #t)
      (ejecutar-ok "letrec iterar (f, x, k) = if ==(k, 0) then x else apply iterar (f, apply f (x), sub1(k)) end in apply iterar (proc (z) *(z, 2) end, 1, 5) end" 32)
      (ejecutar-ok "let dia = 3 in case dia of 1 => 100 of 3 => 300 of 7 => 700 otherwise => 0 end end" 300)
      (ejecutar-ok "case 2 of 2 => 10 of 2 => 20 otherwise => 0 end" 10)
      (ejecutar-ok "case 9 of 1 => 1 otherwise => 99 end" 99))

    (test-case "errores del enunciado"
      (ejecutar-error "if 1 then 2 else 3 end")
      (ejecutar-error "zzz")
      (ejecutar-error "apply 5 (1)")
      (ejecutar-error "let f = proc (x) x end in apply f (1, 2) end")
      (ejecutar-error "let f = proc (x, y) x end in apply f (1) end")
      (ejecutar-error "+(1, true)")
      (ejecutar-error "not(5)")
      (ejecutar-error "case true of 1 => 1 otherwise => 0 end"))))

(run-tests suite-taller-extra)
