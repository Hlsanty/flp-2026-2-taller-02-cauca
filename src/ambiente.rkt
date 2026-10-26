#lang eopl
;Autores: Santiago Alexander Criollo 2380661-3743

;; Taller 2 — El intérprete de Cauca.
;; El TAD ambiente, la búsqueda de ligaduras y el ambiente inicial.
;; Requiere sintaxis.rkt y valores.rkt.
;;
;; Aquí se declara con define-datatype el tipo ambiente, con tres
;; variantes:
;;
;;   ambiente-vacio()
;;   ambiente-extendido(ids, valores, env)
;;     ids      (list-of symbol?)
;;     valores  list?
;;     env      ambiente?
;;   ambiente-recursivo(proc-names, idss, bodies, env)
;;     proc-names  (list-of symbol?)   los nombres declarados en el letrec
;;     idss        list?               la lista de parámetros de cada uno
;;     bodies      (list-of expresion?) los cuerpos, guardados sin evaluar
;;     env         ambiente?
;;
;; La variante recursiva no construye clausuras: las arma apply-env en el
;; momento de la búsqueda, y el ambiente que les entrega es el propio
;; ambiente-recursivo (EOPL, sección 3.4, figura 3.9).

(require "sintaxis.rkt")
(require "valores.rkt")

;; ambiente : tipo de dato
;; Tres variantes: vacío, extendido y recursivo (para letrec). El recursivo
;; guarda nombres, parámetros y cuerpos sin evaluar; apply-env arma la
;; clausura al buscar, entregándole el propio ambiente recursivo.
(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido
   (ids (list-of symbol?))
   (valores list?)
   (env ambiente?))
  (ambiente-recursivo
   (proc-names (list-of symbol?))
   (idss list?)
   (bodies (list-of expresion?))
   (env ambiente?)))

;; posicion : symbol x lista x entero -> entero o #f
;; Retorna el índice del símbolo en la lista (contando desde i), o #f si no está.
(define posicion
  (lambda (id lista i)
    (cond
      ((null? lista) #f)
      ((eqv? (car lista) id) i)
      (else (posicion id (cdr lista) (+ i 1))))))

;; apply-env : ambiente x symbol -> valor
;; Busca el identificador en el ambiente, respetando el shadowing de las
;; ligaduras más recientes, y levanta eopl:error si no está ligado.
(define apply-env
  (lambda (env id)
    (cases ambiente env
           (ambiente-vacio ()
             (eopl:error 'apply-env "Variable no ligada: ~s" id))
           (ambiente-extendido (ids valores amb)
             (let ((pos (posicion id ids 0)))
               (if pos
                   (list-ref valores pos)
                   (apply-env amb id))))
           (ambiente-recursivo (proc-names idss bodies amb)
             (let ((pos (posicion id proc-names 0)))
               (if pos
                   (cerradura (list-ref idss pos) (list-ref bodies pos) env)
                   (apply-env amb id)))))))

;; ambiente-inicial : -> ambiente
;; El ambiente con que arranca todo programa:
;; n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r) '(10 3 7 2 5) (ambiente-vacio))))

(provide (all-defined-out))
