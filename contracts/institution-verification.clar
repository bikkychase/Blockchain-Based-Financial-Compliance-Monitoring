;; Institution Verification Contract
;; This contract validates financial entities participating in the system

(define-data-var admin principal tx-sender)

;; Data map to store verified institutions
(define-map verified-institutions
  principal
  {
    institution-name: (string-utf8 100),
    registration-number: (string-utf8 50),
    verified: bool,
    verification-date: uint
  }
)

;; Function to register a new institution (admin only)
(define-public (register-institution
                (institution principal)
                (name (string-utf8 100))
                (reg-number (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100)) ;; Only admin can register
    (asserts! (is-none (map-get? verified-institutions institution)) (err u101)) ;; Ensure not already registered

    (map-set verified-institutions
      institution
      {
        institution-name: name,
        registration-number: reg-number,
        verified: true,
        verification-date: block-height
      }
    )
    (ok true)
  )
)

;; Function to check if an institution is verified
(define-read-only (is-verified-institution (institution principal))
  (match (map-get? verified-institutions institution)
    institution-data (ok (get verified institution-data))
    (ok false)
  )
)

;; Function to revoke verification (admin only)
(define-public (revoke-verification (institution principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (match (map-get? verified-institutions institution)
      institution-data
        (begin
          (map-set verified-institutions
            institution
            (merge institution-data { verified: false })
          )
          (ok true)
        )
      (err u102) ;; Institution not found
    )
  )
)

;; Function to set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (var-set admin new-admin)
    (ok true)
  )
)
