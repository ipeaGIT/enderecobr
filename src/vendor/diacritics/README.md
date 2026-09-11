# Diacritics
This is a rust crate for removing diacritics from a string. It can be useful when wanting to standardize some material to make it easier to search, among other things. 

## Example

```rust
let string = "TÅRÖÄÆØ";
let new_string = diacritics::remove_diacritics(string);
assert_eq!("TAROAAO", new_string);
```
