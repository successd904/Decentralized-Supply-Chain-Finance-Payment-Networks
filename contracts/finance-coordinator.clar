(define-constant ERR-INVALID-INPUT (err u1000))
(define-constant ERR-NOT-AUTHORIZED (err u1001))
(define-constant ERR-ALREADY-INITIALIZED (err u1002))
(define-constant ERR-NOT-INITIALIZED (err u1003))
(define-constant ERR-SCORE-TOO-LOW (err u1004))

(define-data-var is-initialized bool false)
(define-data-var authorized-address principal tx-sender)
(define-data-var current-score uint u0)

(define-read-only (is-authorized)
  (is-eq tx-sender (var-get authorized-address))
)

(define-public (initialize (initial-authorized-address principal))
  (begin
    (asserts! (not (var-get is-initialized)) ERR-ALREADY-INITIALIZED)
    (var-set authorized-address initial-authorized-address)
    (var-set is-initialized true)
    (ok true)
  )
)
``
(define-public (update-score (new-score uint))
  (begin
    (asserts! (var-get is-initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-score u100) ERR-INVALID-INPUT)
    (asserts! (>= new-score (var-get current-score)) ERR-SCORE-TOO-LOW)
    (var-set current-score new-score)
    (ok true)
  )
)

(define-read-only (get-score)
  (var-get current-score)
)

(define-read-only (get-authorized-address)
  (var-get authorized-address)
)
