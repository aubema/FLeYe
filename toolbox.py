#!/usr/bin/env python3

import numpy as np
import rawpy


def open_raw(fname, band_list="RGB"):
    try:
        raw = rawpy.imread(fname)
    except rawpy.LibRawFileUnsupportedError:
        raise TypeError("Unsupported file format")

    h = raw.sizes.height // 2
    w = raw.sizes.width // 2

    data = (
        raw.raw_image_visible.reshape(h, 2, w, 2)
        .transpose((1, 3, 0, 2))
        .reshape(4, h, w)
    ) / raw.white_level

    bands_mask = (
        np.array(list(raw.color_desc.decode()))[raw.raw_pattern.flatten()]
        == np.array(list(band_list))[:, None]
    )

    return np.stack(
        [np.mean(data[b], axis=0) if sum(b) > 1 else data[b][0] for b in bands_mask],
        axis=-1,
    )


def to_grayscale(im, weights, normalize=False):
    weights = np.array(weights)
    if not weights.shape:
        weights = np.ones(im.shape[-1]) * weights

    if normalize:
        weights /= weights.sum()

    return np.dot(im, weights)
