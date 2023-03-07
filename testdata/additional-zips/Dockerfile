# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# default release image
# -----------------------------------
FROM alpine:latest AS default

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
COPY dist/$TARGETOS/$TARGETARCH/test_additional_one /bin/
COPY dist/$TARGETOS/$TARGETARCH/test_additional_two /bin/

USER 100
CMD ["/bin/$BIN_NAME", "default"]


# alternative release image
# -----------------------------------
FROM alpine:latest AS alternative

ARG BIN_NAME
# Export BIN_NAME for the CMD below, it can't see ARGs directly.
ENV BIN_NAME=$BIN_NAME
ARG PRODUCT_VERSION
ARG PRODUCT_REVISION
ARG PRODUCT_NAME=$BIN_NAME
# TARGETOS and TARGETARCH are set automatically wen --platform is provided.
ARG TARGETOS TARGETARCH

LABEL maintainer="Team RelEng <team-rel-eng@hashicorp.com>"
LABEL version=$PRODUCT_VERSION
LABEL revision=$PRODUCT_REVISION

COPY dist/$TARGETOS/$TARGETARCH/$BIN_NAME /bin/
COPY dist/$TARGETOS/$TARGETARCH/test-additional-one /bin/
COPY dist/$TARGETOS/$TARGETARCH/test-additional-two /bin/

USER 100
CMD ["/bin/$BIN_NAME", "alternative"]
