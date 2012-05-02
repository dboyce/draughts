
test:
	@mocha \
		--reporter list

clean:
	@rm -rf target
	@mkdir target

app:
	@mkdir -p target/js
	@coffee -j app.js -o target/js -c lib

webapp: clean app
	@cp -r public/* target

.PHONY: test clean app webapp
