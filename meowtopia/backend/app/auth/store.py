from datetime import datetime
from typing import Dict, Any

# In-memory store for demo/dev. Replace with a DB in production.
# user shape documented in original monolithic file
USERS_BY_EMAIL: Dict[str, Dict[str, Any]] = {}

# temp 2FA challenges: token -> {"email": str, "exp": datetime}
TWOFA_TEMP_TOKENS: Dict[str, Dict[str, Any]] = {}

