from utils.generate_passwords import generate_passwords


def test_generate_passwords_length():
    passwords = generate_passwords(3, length=8)
    assert len(passwords) == 3
    assert all(len(p) == 8 for p in passwords)


