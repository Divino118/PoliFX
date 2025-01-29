;; PoliFX Marketplace Smart Contract
;; This contract allows users to create prediction markets for policy outcomes,
;; place bets, resolve markets, claim winnings, and handles market expiration.

;; Constants
(define-constant ERROR-INVALID-CLOSE-TIME (err u1))
(define-constant ERROR-MARKET-INACTIVE (err u2))
(define-constant ERROR-MARKET-RESOLVED (err u3))
(define-constant ERROR-INVALID-WAGER (err u4))
(define-constant ERROR-MARKET-NOT-EXISTS (err u5))
(define-constant ERROR-INSUFFICIENT-BALANCE (err u6))
(define-constant ERROR-MARKET-ACTIVE (err u7))
(define-constant ERROR-WAGER-NOT-EXISTS (err u8))
(define-constant ERROR-MARKET-UNRESOLVED (err u9))
(define-constant ERROR-WAGER-LOST (err u10))
(define-constant ERROR-MARKET-TIMEOUT (err u11))
(define-constant ERROR-MARKET-VALID (err u12))
(define-constant ERROR-UNAUTHORIZED (err u13))
(define-constant ERROR-WAGER-MIN (err u14))
(define-constant ERROR-WAGER-MAX (err u15))
(define-constant ERROR-INVALID-INPUT (err u16))

;; Additional Constants for Validation
(define-constant MAX-BLOCKS-UNTIL-CLOSE u52560) ;; Maximum ~1 year worth of blocks
(define-constant MIN-BLOCKS-UNTIL-CLOSE u144)   ;; Minimum ~1 day worth of blocks
(define-constant MAX-BLOCKS-UNTIL-TIMEOUT u105120) ;; Maximum ~2 years worth of blocks
(define-constant MIN-DESC-LENGTH u10)         ;; Minimum description length

;; Data Variables
(define-data-var platform-name (string-ascii 50) "PoliFX Marketplace")
(define-data-var next-prediction-market-id uint u1)
(define-data-var admin principal tx-sender)

;; Configuration
(define-data-var market-resolution-period uint u10000)
(define-data-var minimum-bet-amount uint u10)
(define-data-var maximum-bet-amount uint u1000000)

;; Maps
(define-map markets
  { market-id: uint }
  {
    description: (string-ascii 256),
    outcome: (optional bool),
    betting-close-time: uint,
    resolution-deadline: uint,
    creator: principal
  }
)

(define-map wagers
  { market-id: uint, participant: principal }
  { bet-amount: uint, prediction: bool }
)

;; Enhanced Private Validation Functions
(define-private (is-valid-market-id (market-id uint))
  (< market-id (var-get next-prediction-market-id))
)

(define-private (is-valid-desc-length (desc (string-ascii 256)))
  (and 
    (>= (len desc) MIN-DESC-LENGTH)
    (<= (len desc) u256)
  )
)

(define-private (is-valid-close-time (betting-close-time uint))
  (let 
    (
      (blocks-until-close (- betting-close-time u0))
    )
    (and
      (>= blocks-until-close MIN-BLOCKS-UNTIL-CLOSE)
      (<= blocks-until-close MAX-BLOCKS-UNTIL-CLOSE)
    )
  )
)

(define-private (is-valid-timeout-time (betting-close-time uint) (resolution-deadline uint))
  (let
    (
      (blocks-until-timeout (- resolution-deadline betting-close-time))
    )
    (and
      (> resolution-deadline betting-close-time)
      (<= blocks-until-timeout MAX-BLOCKS-UNTIL-TIMEOUT)
    )
  )
)

(define-private (is-valid-wager-amount (amount uint))
  (and
    (>= amount (var-get minimum-bet-amount))
    (<= amount (var-get maximum-bet-amount))
  )
)

;; Public Functions

;; Create a new market with enhanced validation
(define-public (create-market (description (string-ascii 256)) (betting-close-time uint))
  (let
    (
      (market-id (var-get next-prediction-market-id))
      (resolution-deadline (+ betting-close-time (var-get market-resolution-period)))
    )
    ;; Enhanced input validation
    (asserts! (is-valid-desc-length description) ERROR-INVALID-INPUT)
    (asserts! (is-valid-close-time betting-close-time) ERROR-INVALID-CLOSE-TIME)
    (asserts! (is-valid-timeout-time betting-close-time resolution-deadline) ERROR-INVALID-INPUT)
    
    (map-set markets
      { market-id: market-id }
      {
        description: description,
        outcome: none,
        betting-close-time: betting-close-time,
        resolution-deadline: resolution-deadline,
        creator: tx-sender
      }
    )
    (var-set next-prediction-market-id (+ market-id u1))
    (ok market-id)
  )
)

;; Place a wager on a market with enhanced validation
(define-public (place-wager (market-id uint) (prediction bool) (bet-amount uint))
  (let
    (
      (existing-wager (default-to { bet-amount: u0, prediction: false } 
                      (map-get? wagers { market-id: market-id, participant: tx-sender })))
    )
    ;; Enhanced input validation
    (asserts! (is-valid-market-id market-id) ERROR-MARKET-NOT-EXISTS)
    (asserts! (is-valid-wager-amount bet-amount) ERROR-INVALID-WAGER)
    (let
      (
        (market (unwrap! (map-get? markets { market-id: market-id }) ERROR-MARKET-NOT-EXISTS))
        (total-bet-amount (+ bet-amount (get bet-amount existing-wager)))
      )
      ;; Additional validation for combined wager amount
      (asserts! (<= total-bet-amount (var-get maximum-bet-amount)) ERROR-WAGER-MAX)
      (asserts! (is-none (get outcome market)) ERROR-MARKET-RESOLVED)
      (asserts! (>= (stx-get-balance tx-sender) bet-amount) ERROR-INSUFFICIENT-BALANCE)
      
      (map-set wagers
        { market-id: market-id, participant: tx-sender }
        { bet-amount: total-bet-amount, prediction: prediction }
      )
      (stx-transfer? bet-amount tx-sender (as-contract tx-sender))
    )
  )
)

;; Enhanced setter for market resolution period with stricter validation
(define-public (set-market-resolution-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (>= new-period u1000)  ;; Minimum ~1 day worth of blocks
      (<= new-period u52560) ;; Maximum ~1 year worth of blocks
    ) ERROR-INVALID-INPUT)
    (ok (var-set market-resolution-period new-period))
  )
)

;; Enhanced setter for minimum bet amount with stricter validation
(define-public (set-minimum-bet-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (>= new-amount u1)
      (< new-amount (var-get maximum-bet-amount))
      (<= new-amount u1000000) ;; Upper limit for minimum wager
    ) ERROR-INVALID-INPUT)
    (ok (var-set minimum-bet-amount new-amount))
  )
)

;; Enhanced setter for maximum bet amount with stricter validation
(define-public (set-maximum-bet-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (> new-amount (var-get minimum-bet-amount))
      (<= new-amount u1000000000000)
      (>= new-amount u1000) ;; Lower limit for maximum wager
    ) ERROR-INVALID-INPUT)
    (ok (var-set maximum-bet-amount new-amount))
  )
)

;; Getter for admin
(define-read-only (get-admin)
  (ok (var-get admin))
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERROR-UNAUTHORIZED)
    (asserts! (not (is-eq new-admin (var-get admin))) ERROR-INVALID-INPUT)
    (ok (var-set admin new-admin))
  )
)