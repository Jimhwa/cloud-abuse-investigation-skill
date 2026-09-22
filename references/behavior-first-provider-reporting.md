# Behavior-First Investigation, Provider-Second Reporting

## Principle

Group suspicious traffic by **behavior first**.

Group by cloud provider / ASN later when preparing abuse submissions.

Provider co-location is infrastructure context, not by itself a campaign
fingerprint.

## Investigation layer

Start with reproducible behavior such as:

- exact or rare request sequence;
- unusual Referer pattern;
- repeated path family;
- protocol fingerprint;
- timing / burst structure;
- sparse-vs-full browser behavior;
- cross-protocol corroboration;
- repeated uncommon client fingerprints.

A behavior family can span multiple ASNs or providers.

## Reporting layer

After a behavior family is established:

1. resolve source addresses to current BGP/RDAP attribution;
2. split evidence by provider / ASN / prefix;
3. create provider-specific IP lists;
4. include only that provider's addresses in its report;
5. mention cross-provider similarity only as contextual evidence;
6. do not infer a common tenant/controller without direct support.

## Negative controls

Keep normal-browser or benign examples that superficially share one feature
with the suspicious set. They are useful regression tests for detector rules.
