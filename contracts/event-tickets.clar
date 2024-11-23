;; Event Ticket Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-ticket-not-found (err u101))
(define-constant err-ticket-not-for-sale (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-unauthorized (err u104))

;; Data Variables
(define-data-var next-ticket-id uint u0)

;; Define ticket types
(define-non-fungible-token event-ticket uint)

;; Ticket data map
(define-map tickets
    uint
    {
        owner: principal,
        event-name: (string-ascii 50),
        price: uint,
        for-sale: bool,
        used: bool
    }
)

;; Create new ticket
(define-public (mint-ticket (event-name (string-ascii 50)) (price uint))
    (let
        (
            (ticket-id (var-get next-ticket-id))
        )
        (if (is-eq tx-sender contract-owner)
            (begin
                (try! (nft-mint? event-ticket ticket-id tx-sender))
                (map-set tickets ticket-id {
                    owner: tx-sender,
                    event-name: event-name,
                    price: price,
                    for-sale: false,
                    used: false
                })
                (var-set next-ticket-id (+ ticket-id u1))
                (ok ticket-id)
            )
            err-owner-only
        )
    )
)

;; List ticket for sale
(define-public (list-ticket (ticket-id uint) (price uint))
    (let
        (
            (ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found))
        )
        (if (and
                (is-eq (get owner ticket) tx-sender)
                (not (get used ticket))
            )
            (begin
                (map-set tickets ticket-id (merge ticket {
                    price: price,
                    for-sale: true
                }))
                (ok true)
            )
            err-unauthorized
        )
    )
)

;; Buy ticket
(define-public (buy-ticket (ticket-id uint))
    (let
        (
            (ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found))
            (price (get price ticket))
            (seller (get owner ticket))
        )
        (if (and
                (get for-sale ticket)
                (not (get used ticket))
            )
            (begin
                (try! (stx-transfer? price tx-sender seller))
                (try! (nft-transfer? event-ticket ticket-id seller tx-sender))
                (map-set tickets ticket-id (merge ticket {
                    owner: tx-sender,
                    for-sale: false
                }))
                (ok true)
            )
            err-ticket-not-for-sale
        )
    )
)

;; Mark ticket as used
(define-public (use-ticket (ticket-id uint))
    (let
        (
            (ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found))
        )
        (if (is-eq (get owner ticket) tx-sender)
            (begin
                (map-set tickets ticket-id (merge ticket {
                    used: true,
                    for-sale: false
                }))
                (ok true)
            )
            err-unauthorized
        )
    )
)

;; Read-only functions
(define-read-only (get-ticket (ticket-id uint))
    (map-get? tickets ticket-id)
)

(define-read-only (get-ticket-owner (ticket-id uint))
    (get owner (unwrap! (map-get? tickets ticket-id) err-ticket-not-found))
)
