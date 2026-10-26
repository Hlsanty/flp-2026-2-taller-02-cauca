#lang eopl
;Autores: Santiago Alexander Criollo 2380661-3743

;; Taller 2 — El intérprete de Cauca.
;; El valor procedimiento. Requiere sintaxis.rkt.
;;
;; Aquí se declara con define-datatype el tipo procval, con un solo
;; constructor:
;;
;;   cerradura(ids, body, env)
;;     ids   (list-of symbol?)  los parámetros del procedimiento
;;     body  expresion?         el cuerpo, guardado sin evaluar
;;     env                      el ambiente vigente donde se definió
;;
;; El campo env se declara con un predicado que acepta cualquier valor,
;; (env (lambda (v) #t)). Exigir ambiente? obligaría a requerir
;; ambiente.rkt desde aquí, y ambiente.rkt ya requiere este módulo para
;; construir clausuras al resolver letrec: Racket no carga dos módulos
;; que se requieran entre sí, levanta cycle in loading. Es el único
;; campo que queda sin verificar.

(require "sintaxis.rkt")
;; procval : tipo de dato
;; Valor procedimiento. cerradura guarda parámetros, cuerpo sin evaluar y el
;; ambiente de definición. El campo env acepta cualquier valor para evitar el
;; ciclo de módulos con ambiente.rkt.
(define-datatype procval procval?
  (cerradura
   (ids (list-of symbol?))
   (body expresion?)
   (env (lambda (v) #t))))

(provide (all-defined-out))
