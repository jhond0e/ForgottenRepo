# ForgottenRepo
Discovering private or deleted github repositories through exposed .git/config on LeakIX

### Install
```bash
git clone https://github.com/jhond0e/ForgottenRepo
cd ForgottenRepo
chmod +x scanner.sh
nano scanner.sh # Change API_KEY value with your own (free) LeakIX api key
```

### Usage
```
Usage: scanner.sh -u <user> [-o <output_file>]
Options:
  -u <user>           Specify the GitHub user to search for.
  -o <output_file>    (Optional) Save the results to a file instead of displaying them.
```

### Example
```bash
./scanner.sh -u NationalSecurityAgency -o classified.txt
```
