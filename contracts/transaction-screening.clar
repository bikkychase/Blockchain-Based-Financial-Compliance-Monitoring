;; Transaction Screening Contract
;; Checks financial activities against compliance rules

(define-data-var admin principal tx-sender)

;; Data map to store screening rules
(define-map screening-rules
  uint  ;; rule-id
  {
    rule-name: (string-utf8 100),
    description: (string-utf8 500),
    threshold-amount: uint,
    high-risk: bool,
    active: bool
  }
)

;; Counter for rule IDs
(define-data-var rule-counter uint u0)

;; Data structure for transaction records
(define-map screened-transactions
  uint  ;; transaction-id
  {
    sender: principal,
    receiver: principal,
    amount: uint,
    timestamp: uint,
    passed-screening: bool,
    rule-violations: (list 10 uint) ;; List of violated rule IDs
  }
)

;; Counter for transaction IDs
(define-data-var transaction-counter uint u0)

;; Function to add a new screening rule (admin only)
(define-public (add-screening-rule
                (name (string-utf8 100))
                (description (string-utf8 500))
                (threshold uint)
                (high-risk bool))
  (let ((new-id (+ (var-get rule-counter) u1)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))

    (map-set screening-rules
      new-id
      {
        rule-name: name,
        description: description,
        threshold-amount: threshold,
        high-risk: high-risk,
        active: true
      }
    )
    (var-set rule-counter new-id)
    (ok new-id)
  )
)

;; Function to screen a transaction
(define-public (screen-transaction
                (sender principal)
                (receiver principal)
                (amount uint))
  (let ((new-id (+ (var-get transaction-counter) u1))
        (violations (screen-for-violations amount)))

    (map-set screened-transactions
      new-id
      {
        sender: sender,
        receiver: receiver,
        amount: amount,
        timestamp: block-height,
        passed-screening: (is-eq (len violations) u0),
        rule-violations: violations
      }
    )
    (var-set transaction-counter new-id)
    (ok new-id)
  )
)

;; Helper function to check for rule violations
(define-private (screen-for-violations (amount uint))
  (let ((violations (list)))
    ;; In a real implementation, this would iterate through all rules and check them
    ;; For simplicity, we're just checking against a threshold
    (if (> amount u10000)
        (unwrap-panic (as-max-len? (append violations u1) u10))
        violations)
  )
)

;; Function to get transaction details
(define-read-only (get-transaction-details (transaction-id uint))
  (map-get? screened-transactions transaction-id)
)

;; Function to deactivate a rule (admin only)
(define-public (deactivate-rule (rule-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (match (map-get? screening-rules rule-id)
      rule-data
        (begin
          (map-set screening-rules
            rule-id
            (merge rule-data { active: false })
          )
          (ok true)
        )
      (err u102) ;; Rule not found
    )
  )
)
