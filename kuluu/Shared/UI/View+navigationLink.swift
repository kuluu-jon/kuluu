//
//  View+navigationLink.swift
//  ffxi
//
//  Created by kuluu-jon on 5/7/22.
//

import SwiftUI

extension View {
    func navigationLink<Model, Destination: View>(
        item: Binding<Model?>,
        @ViewBuilder destination: @escaping (Model) -> Destination
    ) -> some View {
        self.modifier(NavigationViewModifier(item: item, destination: destination))
    }

    @ViewBuilder
    func navigationLink<Destination: View>(
        isActive: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        var proxy: IdentifiableProxy? = IdentifiableProxy()
        let proxyBinding = Binding<IdentifiableProxy?>(
            get: { isActive.wrappedValue ? proxy : nil },
            set: {
                proxy = $0
                isActive.wrappedValue = proxy != nil
            }
        )
        self.modifier(NavigationViewModifier(item: proxyBinding, destination: { _ in destination() }))
    }
}

private struct IdentifiableProxy: Identifiable {
    let id = UUID()
}

struct NavigationViewModifier<Item, Destination: View>: ViewModifier {
    @Binding var item: Item?
    let destination: (Item) -> Destination

    func body(content: Content) -> some View {
        content
            .background(self.background)
    }

    var background: some View {
        NavigationLink(
            destination: item.map { destination($0) },
            isActive: binding,
            label: {}
        )
    }

    var binding: Binding<Bool> {
        Binding(
            get: { item != nil },
            set: { value in
                guard !value else { return }
                item = nil
            }
        )
    }
}
