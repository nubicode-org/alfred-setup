# Security Awareness Training: companion material

Goes with the **Security Awareness Training** course on Alfred Learning. The course is complete
without these files; they turn what it teaches into something you keep.

- [personal-security-checklist.md](personal-security-checklist.md): the course's habits as a list to
  work through on your own accounts and devices, one sitting at a time.
- [incident-playbook.md](incident-playbook.md): a template for the course's capstone, the personal
  playbook. Fill it in now, while nothing is wrong, so you are not deciding under pressure.

Commands the course uses, to try on your own machine:

```bash
# Where does a link really go? Follow redirects without opening it in a browser.
curl -sIL "https://example.com/some/link" | grep -i '^location:'

# Who issued a site's certificate, and when does it expire?
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \
  | openssl x509 -noout -issuer -subject -dates

# Has a password appeared in a breach? Only the first 5 characters of its hash leave your machine.
hash=$(printf '%s' 'the-password' | openssl dgst -sha1 -r | awk '{print toupper($1)}')
curl -s "https://api.pwnedpasswords.com/range/${hash:0:5}" | grep "${hash:5}" || echo "not found"
```

The last one uses k-anonymity, as the course explains: the service never sees the password or its
full hash. Type the password into a script like this only on your own computer, and clear your shell
history afterwards if you did (`history -c` in bash).
