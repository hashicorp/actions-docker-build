# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
FROM alpine:latest AS default

ARG FOO
ARG BAR
ARG BIN_NAME
# Export BIN_NAME for the CMD below, it can't see ARGs directly.
ENV BIN_NAME=$BIN_NAME
ARG PRODUCT_VERSION
ARG PRODUCT_REVISION
ARG PRODUCT_NAME=$BIN_NAME
# TARGETOS and TARGETARCH are set automatically when --platform is provided.
ARG TARGETOS TARGETARCH

LABEL maintainer="Team RelEng <team-rel-eng@hashicorp.com>"
LABEL version=$PRODUCT_VERSION
LABEL revision=$PRODUCT_REVISION

COPY dist/$TARGETOS/$TARGETARCH/$BIN_NAME /bin/

# Fail if FOO is not set
RUN test -n "$FOO" || (echo "FOO not set" && false)

USER 100
CMD ["/bin/$BIN_NAME", "default"]
