(load "mk/test-check.scm")
(load "evalo-standard.scm")

(run 1 (p q)
     (== p q))

(run 1 (p q)
     (=/= p q)
     (== p q))

;; Succeed example
(run 1 (q)
  (evalo
    `(cons 1 '(2))
    '(1 2)))

;; Failed example
(run 1 (q)
  (evalo
    `(cons 1 '(2))
    '(1 2 3)))

(run 1 (q)
  (evalo
    `(cons 1 '(2))
    q))

(define (append xs ys)
  (cond 
    [(null? xs) ys]
    [else (cons (car xs) (append (cdr xs) ys))]))

;; Succeed where q is unbound
(run 1 (q)
     (evalo `(letrec ([append
                        (lambda (xs ys)
                          (if (null? xs) 
                              ys
                              (cons (car xs) (append (cdr xs) ys))))])
               (append '(1 2 3) '(4 5 6)))
            '(1 2 3 4 5 6)))

;; Succeed where q is '(1 2 3 4 5 6)
(run 1 (q)
     (evalo `(letrec ([append
                        (lambda (xs ys)
                          (if (null? xs) 
                              ys
                              (cons (car xs) (append (cdr xs) ys))))])
               (append '(1 2 3) '(4 5 6)))
            q))

;; Succeed where q is '(4 5 6)
(run 1 (q)
     (evalo `(letrec ([append
                        (lambda (xs ys)
                          (if (null? xs) 
                              ys
                              (cons (car xs) (append (cdr xs) ys))))])
               (append '(1 2 3) ,q))
            '(1 2 3 4 5 6)))

;; Succeed where q is '(1 2 3)
(run 1 (q)
     (evalo `(letrec ([append
                        (lambda (xs ys)
                          (if (null? xs) 
                              ys
                              (cons (car xs) (append (cdr xs) ys))))])
               (append ,q '(4 5 6)))
            '(1 2 3 4 5 6)))

;; Succeed where q is ys
(run 1 (q)
     (evalo `(letrec ([append
                        (lambda (xs ys)
                          (if (null? xs) 
                              ,q
                              (cons (car xs) (append (cdr xs) ys))))])
               (append '(1 2 3) '(4 5 6)))
            '(1 2 3 4 5 6)))

;; Succeed where q is (equal xs '())
(run 1 (q)
     (evalo `(letrec ([append
                        (lambda (xs ys)
                          (if ,q
                              ys
                              (cons (car xs) (append (cdr xs) ys))))])
               (append '(1 2 3) '(4 5 6)))
            '(1 2 3 4 5 6)))

;; Succeed, but q is '(1 2 3 4 5 6)
(run 1 (q)
     (evalo `(letrec ([append
                        (lambda (xs ys)
                          (if (null? xs)
                              ys
                              ,q))])
               (append '(1 2 3) '(4 5 6)))
            '(1 2 3 4 5 6)))

;; Succeed, but the program is not what we want
(run 1 (q)
     (evalo `(letrec ([append
                        (lambda (xs ys)
                          (if (null? xs)
                              ys
                              ,q))])
               (list (append '() '())
                     (append '() '(2 3 4))
                     (append '(1 2 3) '())
                     (append '(1) '(2))
                     (append '(3) '(4))
                     (append '(1 2 3) '(4 5 6))))
            (list '()
                  '(2 3 4)
                  '(1 2 3)
                  '(1 2)
                  '(3 4)
                  '(1 2 3 4 5 6))))

(set! allow-incomplete-search? #t)
(load "evalo-optmized.scm")

;; Succeed, where q is (if (null? ys) 
;;                         xs 
;;                         (cons (car xs) (append (cdr xs) ys)))
(run 1 (q)
   (absento 1 q)
   (absento 2 q)
   (absento 3 q)
   (absento 4 q)
   (evalo `(letrec ([append
                      (lambda (xs ys)
                        (if (null? xs)
                            ys
                            ,q))])
             (list (append '() '())
                   (append '(1) '())
                   (append '(1) '(2))
                   (append '(1 2) '(3 4))))
          (list '()
                '(1)
                '(1 2)
                '(1 2 3 4))))

;; Succeed, where q is (if (null? xs)
;;                         ys
;;                         (if (null? ys) 
;;                             xs 
;;                             (cons (car xs) (append (cdr xs) ys))))
(run 1 (q)
   (absento 1 q)
   (absento 2 q)
   (absento 3 q)
   (absento 4 q)
   (evalo `(letrec ([append (lambda (xs ys) ,q)])
             (list (append '() '())
                   (append '(1) '())
                   (append '(1) '(2))
                   (append '(1 2) '(3 4))))
          (list '()
                '(1)
                '(1 2)
                '(1 2 3 4))))

;; Succeed, more faster
(run 1 (q)
   (absento 1 q)
   (absento 2 q)
   (absento 3 q)
   (absento 4 q)
   (evalo `(letrec ([append ,q])
             (list (append '() '())
                   (append '(1) '(2))
                   (append '(1 2) '(3 4))))
          (list '()
                '(1 2)
                '(1 2 3 4))))

;; Succeed, using foldr in the environment
;; q = (if (null? ys) xs (foldr cons ys xs))
(run 1 (q)
   (absento 1 q)
   (absento 2 q)
   (absento 3 q)
   (absento 4 q)
   (evalo `(letrec ([foldr (lambda (f acc xs) 
                             (if (null? xs) 
                                 acc 
                                 (f (car xs) (foldr f acc (cdr xs)))))]
                    [append (lambda (xs ys) ,q)])
             (list (append '() '())
                   (append '(1) '())
                   (append '(1) '(2))
                   (append '(1 2) '(3 4))))
          (list '()
                '(1)
                '(1 2)
                '(1 2 3 4))))

;; Example from `Synthesizing Data Structure Transformations from Input-Output Examples
;; (define rev (lambda (lst) (foldl cons '() lst)))
;; Succeed, using foldr in the environment
;; q = (if (null? lst) lst (foldl cons '() lst))
(run 1 (q)
   (absento 1 q)
   (absento 2 q)
   (absento 3 q)
   (absento 4 q)
   (evalo `(letrec ([foldl (lambda (f acc xs) 
                             (if (null? xs) 
                                 acc 
                                 (foldl f (f (car xs) acc) (cdr xs))))]
                    [rev (lambda (lst) ,q)])
             (list (rev '())
                   (rev '(1))
                   (rev '(1 2 3))
                   (rev '(1 2 3 4))))
          (list '()
                '(1)
                '(3 2 1)
                '(4 3 2 1))))

(run 1 (q)
   (evalo `(letrec ([foldr (lambda (f acc xs) 
                             (if (null? xs) 
                                 acc 
                                 (f (car xs) (foldr f acc (cdr xs)))))]
                    [cprod (lambda (lst)
                             (foldr (lambda (xs yss) 
                                      (foldr (lambda (x zss)
                                               (foldr (lambda (ys qss)
                                                        (cons (cons x ys) qss))
                                                      zss yss))
                                             '() xs))
                                    '(()) lst))])
             (list (cprod '())
                   (cprod '(()))
                   (cprod '( () () ))
                   (cprod '((1 2) (3 4)))
                   (cprod '((1 2 3) (5 6)))))
          (list '(())
                '()
                '()
                '((1 3) (1 4) (2 3) (2 4))
                '((1 5) (1 6) (2 5) (2 6) (3 5) (3 6)))))

;; Succeed where q is (cons x ys)
(run 1 (q)
   (absento 1 q) (absento 2 q)
   (absento 3 q) (absento 4 q)
   (absento 5 q) (absento 6 q)
   (evalo `(letrec ([foldr (lambda (f acc xs) 
                             (if (null? xs) 
                                 acc 
                                 (f (car xs) (foldr f acc (cdr xs)))))]
                    [cprod (lambda (lst)
                             (foldr (lambda (xs yss) 
                                      (foldr (lambda (x zss)
                                               (foldr (lambda (ys qss) (cons ,q qss))
                                                      zss yss))
                                             '() xs))
                                    '(()) lst))])
             (list (cprod '())
                   (cprod '(()))
                   (cprod '( () () ))
                   (cprod '((1 2) (3 4)))
                   (cprod '((1 2 3) (5 6)))))
          (list '(())
                '()
                '()
                '((1 3) (1 4) (2 3) (2 4))
                '((1 5) (1 6) (2 5) (2 6) (3 5) (3 6)))))

;; Can not synthesis
(run 1 (q)
   (absento 1 q) (absento 2 q)
   (absento 3 q) (absento 4 q)
   (absento 5 q) (absento 6 q)
   (evalo `(letrec ([foldr (lambda (f acc xs) 
                             (if (null? xs) 
                                 acc 
                                 (f (car xs) (foldr f acc (cdr xs)))))]
                    [cprod (lambda (lst)
                             (foldr (lambda (xs yss) 
                                      (foldr (lambda (x zss)
                                               (foldr (lambda (ys qss) ,q)
                                                      zss yss))
                                             '() xs))
                                    '(()) lst))])
             (list (cprod '())
                   (cprod '(()))
                   (cprod '( () () ))
                   (cprod '((1 2) (3 4)))
                   (cprod '((1 2 3) (5 6)))))
          (list '(())
                '()
                '()
                '((1 3) (1 4) (2 3) (2 4))
                '((1 5) (1 6) (2 5) (2 6) (3 5) (3 6)))))
