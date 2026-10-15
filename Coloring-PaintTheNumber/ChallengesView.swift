import SwiftUI

/// Daily challenge: today's picture, streak with one rest day per week, and this month's calendar.
struct ChallengesView: View {
    @Environment(Router.self) private var router
    private var store: Store { .shared }
    private let cal = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Challenges").font(.display).foregroundStyle(.ink).padding(.top, 8)
                    todayCard
                    streakCard
                    month.padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(.paper)
            .paperStatusBar()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var todayCard: some View {
        let e = store.challenge(on: .now)
        let status = store.status(e)
        return HStack(spacing: 16) {
            Button { router.painting = e } label: { Thumb(entry: e, caption: false).frame(width: 142) }
                .buttonStyle(.pressable)
                .accessibilityLabel("Open today's challenge, \(e.title)")
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY · \(Date.now.formatted(.dateTime.month(.abbreviated).day()).uppercased())")
                    .font(.eyebrow).tracking(1).foregroundStyle(.accent)
                Text(e.title).font(.heading).foregroundStyle(.ink).lineLimit(2)
                HStack(spacing: 4) { DifficultyDots(difficulty: e.difficulty); Text("· \(e.minutes) min").font(.subheadline).foregroundStyle(.ink2) }
                Group {
                    switch status {
                    case .new: Button("Start painting") { router.painting = e }.buttonStyle(PrimaryButton())
                    case .progress(let v): Button("Continue · \(Int(v * 100))%") { router.painting = e }.buttonStyle(PrimaryButton())
                    case .done: Label("Done for today", systemImage: "checkmark.circle.fill").font(.title3.weight(.semibold)).foregroundStyle(.success).frame(minHeight: 48)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(.surface, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var streakCard: some View {
        let streak = store.streak
        let week = cal.dateInterval(of: .weekOfYear, for: .now)!.start
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill").font(.system(size: 32)).foregroundStyle(.flame)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(streak.current) day streak").font(.title2.weight(.bold)).foregroundStyle(.ink)
                    Text("Best \(max(store.bestStreak, streak.current)) · \(streak.restLeftThisWeek ? "1 rest day left" : "rest day used") this week")
                        .font(.subheadline).foregroundStyle(.ink2)
                }
            }
            HStack {
                ForEach(0..<7, id: \.self) { i in
                    let d = cal.date(byAdding: .day, value: i, to: week)!
                    VStack(spacing: 8) {
                        weekDot(streak.state(d))
                        Text(d.formatted(.dateTime.weekday(.narrow))).font(.subheadline.weight(.medium)).foregroundStyle(.ink2)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(16)
        .background(.surface, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    @ViewBuilder private func weekDot(_ s: DayState) -> some View {
        let size: CGFloat = 38
        switch s {
        case .done:
            Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                .frame(width: size, height: size).background(.flame, in: Circle())
                .accessibilityLabel("Completed")
        case .rest:
            Image(systemName: "moon.zzz.fill").font(.system(size: 15, weight: .semibold)).foregroundStyle(.ink2)
                .frame(width: size, height: size).overlay(Circle().strokeBorder(.ink2.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])))
                .accessibilityLabel("Rest day")
        case .today:
            Circle().strokeBorder(.accent, lineWidth: 2.5).frame(width: size, height: size)
                .accessibilityLabel("Today")
        case .missed:
            Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.ink2)
                .frame(width: size, height: size).background(.well, in: Circle())
                .accessibilityLabel("Missed")
        case .future, .before:
            Circle().fill(.well).frame(width: size, height: size)
                .accessibilityLabel("Upcoming")
        }
    }

    private var month: some View {
        let streak = store.streak
        let interval = cal.dateInterval(of: .month, for: .now)!
        let days = cal.range(of: .day, in: .month, for: .now)!.map { cal.date(byAdding: .day, value: $0 - 1, to: interval.start)! }
        let lead = (cal.component(.weekday, from: interval.start) - cal.firstWeekday + 7) % 7
        let counted = days.filter { $0 <= store.today && $0 >= store.installDay }
        let doneCount = counted.filter { streak.state($0) == .done }.count
        let symbols = Array(cal.veryShortStandaloneWeekdaySymbols[(cal.firstWeekday - 1)...] + cal.veryShortStandaloneWeekdaySymbols[..<(cal.firstWeekday - 1)])
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(Date.now.formatted(.dateTime.month(.wide))).font(.heading).foregroundStyle(.ink)
                Spacer()
                Text("\(doneCount) of \(counted.count) days").font(.subheadline).foregroundStyle(.ink2)
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(symbols.enumerated()), id: \.offset) { Text($0.element).font(.subheadline.weight(.semibold)).foregroundStyle(.ink2) }
                ForEach(0..<lead, id: \.self) { _ in Color.clear.frame(height: 48) }
                ForEach(days, id: \.self) { d in dayCell(d, streak.state(d)) }
            }
            .padding(12)
            .background(.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
    }

    @ViewBuilder private func dayCell(_ d: Date, _ s: DayState) -> some View {
        let n = Text("\(cal.component(.day, from: d))")
        let e = store.challenge(on: d)
        Group {
            switch s {
            case .done:
                Button { router.open(e) } label: {
                    Group {
                        if let img = UIImage(named: e.thumb) { Image(uiImage: img).resizable() } else { Color.well }
                    }
                    .aspectRatio(1, contentMode: .fit).frame(width: 42).clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white, lineWidth: 2))
                    .frame(minWidth: 48, minHeight: 48)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("\(e.title), done")
            case .missed, .rest:
                Button { store.premium ? (router.painting = e) : (router.paywall = true) } label: {
                    ZStack {
                        if s == .rest {
                            RoundedRectangle(cornerRadius: 10).strokeBorder(.ink2.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                            Image(systemName: "moon.zzz.fill").font(.subheadline).foregroundStyle(.ink2)
                        } else {
                            RoundedRectangle(cornerRadius: 10).fill(.well)
                            Image(systemName: store.premium ? "paintbrush" : "lock.fill").font(.subheadline).foregroundStyle(.ink2)
                        }
                    }
                    .frame(width: 42, height: 42)
                    .frame(minWidth: 48, minHeight: 48)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(s == .rest ? "Rest day, tap to paint \(e.title)" : (store.premium ? "Paint \(e.title)" : "Missed day, Premium"))
            case .today:
                Button { router.painting = e } label: {
                    n.font(.body.weight(.bold)).foregroundStyle(.accent)
                        .frame(width: 42, height: 42).overlay(Circle().strokeBorder(.accent, lineWidth: 2.5))
                        .frame(minWidth: 48, minHeight: 48)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Today's challenge, \(e.title)")
            case .future, .before:
                n.font(.body).foregroundStyle(s == .before ? .ink2.opacity(0.75) : .ink2)
                    .frame(minWidth: 48, minHeight: 48)
            }
        }
        .buttonStyle(.pressable)
        .frame(height: 48)
    }
}
