;; Payment Processing Contract
;; Handles supply chain payment processing and transaction management

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-INVALID-STATUS (err u105))

;; Data Variables
(define-data-var next-payment-id uint u1)
(define-data-var total-processed-volume uint u0)

;; Data Maps
(define-map payments
  { payment-id: uint }
  {
    payer: principal,
    payee: principal,
    amount: uint,
    currency: (string-ascii 10),
    status: (string-ascii 20),
    coordinator-id: uint,
    invoice-reference: (string-ascii 50),
    created-block: uint,
    processed-block: (optional uint),
    settlement-date: (optional uint)
  }
)

(define-map payment-details
  { payment-id: uint }
  {
    description: (string-ascii 200),
    due-date: uint,
    discount-rate: uint,
    penalty-rate: uint,
    terms: (string-ascii 100)
  }
)

(define-map user-balances
  { user: principal, currency: (string-ascii 10) }
  { balance: uint }
)

(define-map payment-history
  { user: principal }
  {
    total-sent: uint,
    total-received: uint,
    payment-count: uint,
    last-payment-block: uint
  }
)

;; Public Functions

;; Initialize payment
(define-public (initiate-payment
  (payee principal)
  (amount uint)
  (currency (string-ascii 10))
  (coordinator-id uint)
  (invoice-reference (string-ascii 50))
  (description (string-ascii 200))
  (due-date uint))
  (let
    (
      (payment-id (var-get next-payment-id))
      (payer tx-sender)
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: payer, currency: currency }))))
    )
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (> due-date block-height) ERR-INVALID-INPUT)
    (asserts! (>= current-balance amount) ERR-INSUFFICIENT-FUNDS)

    (map-set payments
      { payment-id: payment-id }
      {
        payer: payer,
        payee: payee,
        amount: amount,
        currency: currency,
        status: "initiated",
        coordinator-id: coordinator-id,
        invoice-reference: invoice-reference,
        created-block: block-height,
        processed-block: none,
        settlement-date: none
      }
    )

    (map-set payment-details
      { payment-id: payment-id }
      {
        description: description,
        due-date: due-date,
        discount-rate: u0,
        penalty-rate: u5,
        terms: "standard"
      }
    )

    ;; Reserve funds
    (map-set user-balances
      { user: payer, currency: currency }
      { balance: (- current-balance amount) }
    )

    (var-set next-payment-id (+ payment-id u1))
    (ok payment-id)
  )
)

;; Process payment
(define-public (process-payment (payment-id uint))
  (let
    (
      (payment (unwrap! (map-get? payments { payment-id: payment-id }) ERR-NOT-FOUND))
      (payer (get payer payment))
      (payee (get payee payment))
      (amount (get amount payment))
      (currency (get currency payment))
      (payee-balance (default-to u0 (get balance (map-get? user-balances { user: payee, currency: currency }))))
    )
    (asserts! (is-eq (get status payment) "initiated") ERR-INVALID-STATUS)
    (asserts! (or (is-eq tx-sender payer) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

    ;; Update payment status
    (map-set payments
      { payment-id: payment-id }
      (merge payment {
        status: "processed",
        processed-block: (some block-height)
      })
    )

    ;; Transfer funds to payee
    (map-set user-balances
      { user: payee, currency: currency }
      { balance: (+ payee-balance amount) }
    )

    ;; Update payment history
    (update-payment-history payer payee amount)

    ;; Update total processed volume
    (var-set total-processed-volume (+ (var-get total-processed-volume) amount))

    (ok true)
  )
)

;; Settle payment
(define-public (settle-payment (payment-id uint))
  (let
    (
      (payment (unwrap! (map-get? payments { payment-id: payment-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq (get status payment) "processed") ERR-INVALID-STATUS)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set payments
      { payment-id: payment-id }
      (merge payment {
        status: "settled",
        settlement-date: (some block-height)
      })
    )

    (ok true)
  )
)

;; Cancel payment
(define-public (cancel-payment (payment-id uint))
  (let
    (
      (payment (unwrap! (map-get? payments { payment-id: payment-id }) ERR-NOT-FOUND))
      (payer (get payer payment))
      (amount (get amount payment))
      (currency (get currency payment))
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: payer, currency: currency }))))
    )
    (asserts! (is-eq (get status payment) "initiated") ERR-INVALID-STATUS)
    (asserts! (or (is-eq tx-sender payer) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

    ;; Refund reserved funds
    (map-set user-balances
      { user: payer, currency: currency }
      { balance: (+ current-balance amount) }
    )

    (map-set payments
      { payment-id: payment-id }
      (merge payment { status: "cancelled" })
    )

    (ok true)
  )
)

;; Deposit funds
(define-public (deposit-funds (amount uint) (currency (string-ascii 10)))
  (let
    (
      (user tx-sender)
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: user, currency: currency }))))
    )
    (asserts! (> amount u0) ERR-INVALID-INPUT)

    (map-set user-balances
      { user: user, currency: currency }
      { balance: (+ current-balance amount) }
    )

    (ok true)
  )
)

;; Private Functions

;; Update payment history
(define-private (update-payment-history (payer principal) (payee principal) (amount uint))
  (let
    (
      (payer-history (default-to { total-sent: u0, total-received: u0, payment-count: u0, last-payment-block: u0 }
                                 (map-get? payment-history { user: payer })))
      (payee-history (default-to { total-sent: u0, total-received: u0, payment-count: u0, last-payment-block: u0 }
                                 (map-get? payment-history { user: payee })))
    )
    (map-set payment-history
      { user: payer }
      {
        total-sent: (+ (get total-sent payer-history) amount),
        total-received: (get total-received payer-history),
        payment-count: (+ (get payment-count payer-history) u1),
        last-payment-block: block-height
      }
    )

    (map-set payment-history
      { user: payee }
      {
        total-sent: (get total-sent payee-history),
        total-received: (+ (get total-received payee-history) amount),
        payment-count: (+ (get payment-count payee-history) u1),
        last-payment-block: block-height
      }
    )
  )
)

;; Read-only Functions

;; Get payment
(define-read-only (get-payment (payment-id uint))
  (map-get? payments { payment-id: payment-id })
)

;; Get payment details
(define-read-only (get-payment-details (payment-id uint))
  (map-get? payment-details { payment-id: payment-id })
)

;; Get user balance
(define-read-only (get-balance (user principal) (currency (string-ascii 10)))
  (default-to u0 (get balance (map-get? user-balances { user: user, currency: currency })))
)

;; Get payment history
(define-read-only (get-payment-history (user principal))
  (map-get? payment-history { user: user })
)

;; Get total processed volume
(define-read-only (get-total-processed-volume)
  (var-get total-processed-volume)
)

;; Get next payment ID
(define-read-only (get-next-payment-id)
  (var-get next-payment-id)
)
