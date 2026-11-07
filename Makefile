.PHONY: setup doctor format check coverage secret-scan hooks test analyze build-staging integration-test

setup:
	bash scripts/bootstrap.sh

doctor:
	bash scripts/doctor.sh

format:
	bash scripts/format.sh

check:
	bash scripts/check.sh

coverage:
	bash scripts/coverage.sh

secret-scan:
	bash scripts/secret-scan.sh

hooks:
	bash scripts/setup-hooks.sh

test:
	@source scripts/_fvm.sh && $$FLUTTER_CMD test --reporter compact

analyze:
	@source scripts/_fvm.sh && $$FLUTTER_CMD analyze

build-staging:
	@source scripts/_fvm.sh && $$FLUTTER_CMD build apk --debug --flavor staging -t lib/main_staging.dart

# Slow: needs a running emulator/device. Not part of `make check` / pre-push.
# DEVICE_ID=emulator-5554 make integration-test
# TARGET=integration_test/browse_flow_test.dart make integration-test
integration-test:
	bash scripts/integration_test.sh