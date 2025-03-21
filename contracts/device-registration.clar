;; Device Registration Contract
;; Records details of critical medical equipment

(define-data-var last-device-id uint u0)

(define-map devices
  { id: uint }
  {
    name: (string-ascii 100),
    model: (string-ascii 100),
    serial-number: (string-ascii 50),
    manufacturer: (string-ascii 100),
    category: (string-ascii 50),
    installation-date: uint,
    owner: principal,
    active: bool
  }
)

;; Register a new medical device
(define-public (register-device
    (name (string-ascii 100))
    (model (string-ascii 100))
    (serial-number (string-ascii 50))
    (manufacturer (string-ascii 100))
    (category (string-ascii 50))
    (installation-date uint)
  )
  (let
    (
      (new-id (+ (var-get last-device-id) u1))
    )
    ;; Update device ID counter
    (var-set last-device-id new-id)

    ;; Store device details
    (map-set devices
      { id: new-id }
      {
        name: name,
        model: model,
        serial-number: serial-number,
        manufacturer: manufacturer,
        category: category,
        installation-date: installation-date,
        owner: tx-sender,
        active: true
      }
    )

    (ok new-id)
  )
)

;; Update device status (active/inactive)
(define-public (update-device-status
    (device-id uint)
    (active bool)
  )
  (let
    (
      (device (unwrap! (map-get? devices { id: device-id }) (err u404)))
    )
    ;; Check if caller is the owner
    (asserts! (is-eq tx-sender (get owner device)) (err u403))

    ;; Update device status
    (map-set devices
      { id: device-id }
      (merge device { active: active })
    )

    (ok true)
  )
)

;; Get device details
(define-read-only (get-device (device-id uint))
  (map-get? devices { id: device-id })
)

;; Get total device count
(define-read-only (get-device-count)
  (var-get last-device-id)
)
