// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_CONVERSIONS_H_
#define FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_CONVERSIONS_H_

#include "flutter/display_list/geometry/dl_geometry_types.h"

#include "flutter/third_party/skia/include/core/SkM44.h"
#include "flutter/third_party/skia/include/core/SkMatrix.h"
#include "flutter/third_party/skia/include/core/SkRRect.h"
#include "flutter/third_party/skia/include/core/SkRect.h"
#include "flutter/third_party/skia/include/core/SkSize.h"

namespace flutter {

static_assert(sizeof(SkPoint) == sizeof(DlPoint));
static_assert(sizeof(SkIPoint) == sizeof(DlIPoint));
static_assert(sizeof(SkSize) == sizeof(DlSize));
static_assert(sizeof(SkISize) == sizeof(DlISize));
static_assert(sizeof(SkRect) == sizeof(DlRect));
static_assert(sizeof(SkIRect) == sizeof(DlIRect));
static_assert(sizeof(SkVector) == sizeof(DlSize));

inline const DlPoint& ToDlPoint(const SkPoint& point) {
  return *reinterpret_cast<const DlPoint*>(&point);
}

inline const DlRect& ToDlRect(const SkRect& rect) {
  return *reinterpret_cast<const DlRect*>(&rect);
}

inline const DlRect ToDlRect(const SkIRect& rect) {
  return DlRect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

inline const DlIRect& ToDlIRect(const SkIRect& rect) {
  return *reinterpret_cast<const DlIRect*>(&rect);
}

inline const DlISize& ToDlISize(const SkISize& size) {
  return *reinterpret_cast<const DlISize*>(&size);
}

inline const DlSize& ToDlSize(const SkVector& vector) {
  return *reinterpret_cast<const DlSize*>(&vector);
}

inline const DlRoundRect ToDlRoundRect(const SkRRect& rrect) {
  return DlRoundRect::MakeRectRadii(
      ToDlRect(rrect.rect()),
      {
          .top_left = ToDlSize(rrect.radii(SkRRect::kUpperLeft_Corner)),
          .top_right = ToDlSize(rrect.radii(SkRRect::kUpperRight_Corner)),
          .bottom_left = ToDlSize(rrect.radii(SkRRect::kLowerLeft_Corner)),
          .bottom_right = ToDlSize(rrect.radii(SkRRect::kLowerRight_Corner)),
      });
}

inline DlMatrix ToDlMatrix(const SkMatrix& matrix) {
  // clang-format off
  return DlMatrix::MakeColumn(
      matrix[SkMatrix::kMScaleX], matrix[SkMatrix::kMSkewY],  0.0f, matrix[SkMatrix::kMPersp0],
      matrix[SkMatrix::kMSkewX],  matrix[SkMatrix::kMScaleY], 0.0f, matrix[SkMatrix::kMPersp1],
      0.0f,                       0.0f,                       1.0f, 0.0f,
      matrix[SkMatrix::kMTransX], matrix[SkMatrix::kMTransY], 0.0f, matrix[SkMatrix::kMPersp2]
  );
  // clang-format on
}

inline DlMatrix ToDlMatrix(const SkM44& matrix) {
  DlMatrix dl_matrix;
  matrix.getColMajor(dl_matrix.m);
  return dl_matrix;
}

inline const SkPoint& ToSkPoint(const DlPoint& point) {
  return *reinterpret_cast<const SkPoint*>(&point);
}

inline const SkPoint* ToSkPoints(const DlPoint* points) {
  return points == nullptr ? nullptr : reinterpret_cast<const SkPoint*>(points);
}

inline SkPoint* ToSkPoints(DlPoint* points) {
  return points == nullptr ? nullptr : reinterpret_cast<SkPoint*>(points);
}

inline const SkRect& ToSkRect(const DlRect& rect) {
  return *reinterpret_cast<const SkRect*>(&rect);
}

inline const SkIRect& ToSkIRect(const DlIRect& rect) {
  return *reinterpret_cast<const SkIRect*>(&rect);
}

inline std::optional<const SkIRect> ToOptSkIRect(
    std::optional<const DlIRect> rect) {
  return rect.has_value() ? std::optional(ToSkIRect(*rect)) : std::nullopt;
}

inline const SkRect* ToSkRect(const DlRect* rect) {
  return rect == nullptr ? nullptr : reinterpret_cast<const SkRect*>(rect);
}

inline const SkRect* ToSkRect(const std::optional<DlRect>& rect) {
  return rect.has_value() ? &ToSkRect(rect.value()) : nullptr;
}

inline SkRect* ToSkRect(DlRect* rect) {
  return rect == nullptr ? nullptr : reinterpret_cast<SkRect*>(rect);
}

inline const SkRect* ToSkRects(const DlRect* rects) {
  return rects == nullptr ? nullptr : reinterpret_cast<const SkRect*>(rects);
}

inline const SkIRect* ToSkIRects(const DlIRect* rects) {
  return rects == nullptr ? nullptr : reinterpret_cast<const SkIRect*>(rects);
}

inline const SkSize& ToSkSize(const DlSize& size) {
  return *reinterpret_cast<const SkSize*>(&size);
}

inline const SkISize& ToSkISize(const DlISize& size) {
  return *reinterpret_cast<const SkISize*>(&size);
}

inline const SkVector& ToSkVector(const DlSize& size) {
  return *reinterpret_cast<const SkVector*>(&size);
}

inline const SkRRect ToSkRRect(const DlRoundRect& round_rect) {
  SkVector radii[4];
  radii[SkRRect::kUpperLeft_Corner] =
      ToSkVector(round_rect.GetRadii().top_left);
  radii[SkRRect::kUpperRight_Corner] =
      ToSkVector(round_rect.GetRadii().top_right);
  radii[SkRRect::kLowerLeft_Corner] =
      ToSkVector(round_rect.GetRadii().bottom_left);
  radii[SkRRect::kLowerRight_Corner] =
      ToSkVector(round_rect.GetRadii().bottom_right);
  SkRRect rrect;
  rrect.setRectRadii(ToSkRect(round_rect.GetBounds()), radii);
  return rrect;
};

// Approximates a rounded superellipse with a round rectangle to the
// best practical accuracy.
//
// Skia does not support rounded superellipses directly, so rendering
// `DlRoundSuperellipses` on Skia requires falling back to RRect.
inline const SkRRect ToApproximateSkRRect(const DlRoundSuperellipse& rse) {
  return ToSkRRect(rse.ToApproximateRoundRect());
};

inline SkMatrix ToSkMatrix(const DlMatrix& matrix) {
  return SkMatrix::MakeAll(matrix.m[0], matrix.m[4], matrix.m[12],  //
                           matrix.m[1], matrix.m[5], matrix.m[13],  //
                           matrix.m[3], matrix.m[7], matrix.m[15]);
}

inline SkM44 ToSkM44(const DlMatrix& matrix) {
  return SkM44::ColMajor(matrix.m);
}

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_CONVERSIONS_H_
