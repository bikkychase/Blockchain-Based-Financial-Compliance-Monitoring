;; Regulatory Requirements Contract
;; Records compliance obligations for financial institutions

(define-data-var admin principal tx-sender)

;; Data map to store regulatory requirements
(define-map regulatory-requirements
  uint  ;; requirement-id
  {
    requirement-name: (string-utf8 100),
    description: (string-utf8 500),
    active: bool,
    creation-date: uint
  }
)

;; Counter for requirement IDs
(define-data-var requirement-counter uint u0)

;; Mapping of institution to their assigned requirements
(define-map institution-requirements
  { institution: principal, requirement-id: uint }
  { assigned: bool, assigned-date: uint }
)

;; Function to add a new regulatory requirement (admin only)
(define-public (add-requirement
                (name (string-utf8 100))
                (description (string-utf8 500)))
  (let ((new-id (+ (var-get requirement-counter) u1)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))

    (map-set regulatory-requirements
      new-id
      {
        requirement-name: name,
        description: description,
        active: true,
        creation-date: block-height
      }
    )
    (var-set requirement-counter new-id)
    (ok new-id)
  )
)

;; Function to assign a requirement to an institution (admin only)
(define-public (assign-requirement-to-institution
                (institution principal)
                (requirement-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (asserts! (is-some (map-get? regulatory-requirements requirement-id)) (err u101))

    (map-set institution-requirements
      { institution: institution, requirement-id: requirement-id }
      { assigned: true, assigned-date: block-height }
    )
    (ok true)
  )
)

;; Function to check if an institution has a specific requirement
(define-read-only (has-requirement (institution principal) (requirement-id uint))
  (match (map-get? institution-requirements { institution: institution, requirement-id: requirement-id })
    requirement-data (ok (get assigned requirement-data))
    (ok false)
  )
)

;; Function to deactivate a requirement (admin only)
(define-public (deactivate-requirement (requirement-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (match (map-get? regulatory-requirements requirement-id)
      requirement-data
        (begin
          (map-set regulatory-requirements
            requirement-id
            (merge requirement-data { active: false })
          )
          (ok true)
        )
      (err u102) ;; Requirement not found
    )
  )
)
