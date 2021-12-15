#!/bin/bash

mix release --overwrite
cp -r apps/emqx/etc/certs _build/dev/rel/emqx/etc/certs
cp temp/sys.config _build/dev/rel/emqx/releases/5.0.0-beta.2-3fdc075b/
