"""The three-pool economy (docs/02_GAME_DESIGN.md #2): bankroll drains only,
winnings accumulates only, pending is a transient per-spin buffer.

D3 (locked): bankroll never receives payouts. The API below enforces this by
construction -- there is no method that adds to bankroll or subtracts from
winnings, so the invariant can't be violated by a caller.
"""

from dataclasses import dataclass


@dataclass
class Pools:
    bankroll: float
    winnings: float = 0.0
    pending: float = 0.0

    def spend_from_bankroll(self, amount: float) -> None:
        if amount < 0:
            raise ValueError("cannot spend a negative amount")
        if amount > self.bankroll + 1e-9:
            raise ValueError(
                f"cannot spend {amount} from bankroll of {self.bankroll}"
            )
        self.bankroll -= amount

    def add_to_pending(self, amount: float) -> None:
        if amount < 0:
            raise ValueError("cannot add a negative payout to pending")
        self.pending += amount

    def commit_pending_to_winnings(self) -> None:
        self.winnings += self.pending
        self.pending = 0.0
